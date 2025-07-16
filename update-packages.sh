#!/usr/bin/env bash
# Package update script for NixOS flake
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory - handle both direct execution and flake app execution
if [[ -n "${FLAKE_ROOT:-}" ]]; then
    SCRIPT_DIR="$FLAKE_ROOT"
elif [[ -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # When run as flake app, try to find flake root
    SCRIPT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
PKGS_DIR="$SCRIPT_DIR/pkgs"

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if we're in a git repo
check_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository!"
        exit 1
    fi
}

# Function to create a backup commit
create_backup_commit() {
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "Working directory has uncommitted changes. Creating backup commit..."
        git add -A
        git commit -m "backup: before package updates $(date +%Y-%m-%d_%H:%M:%S)" || true
    fi
}

# Function to update a Go package
update_go_package() {
    local pkg_file="$1"
    local pkg_name
    pkg_name="$(basename "$pkg_file" .nix)"

    print_info "Updating Go package: $pkg_name"

    # Extract current version and repo info
    local owner repo
    owner=$(grep -oP 'owner = "\K[^"]+' "$pkg_file" || echo "")
    repo=$(grep -oP 'repo = "\K[^"]+' "$pkg_file" || echo "")

    if [[ -z "$owner" || -z "$repo" ]]; then
        print_warning "Could not extract owner/repo for $pkg_name"
        return 1
    fi

    # Get latest release
    local latest_tag
    latest_tag=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | jq -r .tag_name)
    if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
        print_warning "No releases found for $owner/$repo, checking tags..."
        latest_tag=$(curl -s "https://api.github.com/repos/$owner/$repo/tags" | jq -r '.[0].name')
    fi

    if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
        print_error "Could not find latest version for $pkg_name"
        return 1
    fi

    # Clean version (remove 'v' prefix if present)
    local version
    version="${latest_tag#v}"

    print_info "Latest version: $version"

    # Update version in file
    sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" "$pkg_file"

    # Update hash (this will fail, but we'll get the correct hash)
    sed -i "s/hash = \"[^\"]*\"/hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"/" "$pkg_file"

    print_info "Building to get correct hash..."
    if ! nix build -f "$SCRIPT_DIR" "$pkg_name" 2>&1 | tee /tmp/nix-build-output; then
        local correct_hash
        correct_hash=$(grep -oP 'got:\s+\K[^\s]+' /tmp/nix-build-output | tail -1)
        if [[ -n "$correct_hash" ]]; then
            sed -i "s/hash = \"[^\"]*\"/hash = \"$correct_hash\"/" "$pkg_file"
            print_success "Updated $pkg_name to version $version"
        else
            print_error "Could not extract correct hash for $pkg_name"
            return 1
        fi
    else
        print_success "Package built successfully (hash was already correct)"
    fi
}

# Function to update an NPM package
update_npm_package() {
    local pkg_file="$1"
    local pkg_dir pkg_name
    pkg_dir="$(dirname "$pkg_file")"
    pkg_name="$(basename "$pkg_dir")"

    print_info "Updating NPM package: $pkg_name"

    # Extract package name from npmjs
    local npm_name
    npm_name=$(grep -oP 'registry\.npmjs\.org/\K[^/]+/[^/]+' "$pkg_file" | head -1 || echo "")
    if [[ -z "$npm_name" ]]; then
        npm_name=$(grep -oP 'pname = "\K[^"]+' "$pkg_file" || echo "")
    fi

    if [[ -z "$npm_name" ]]; then
        print_warning "Could not extract npm package name for $pkg_name"
        return 1
    fi

    # Get latest version from npm
    local latest_version
    latest_version=$(npm view "$npm_name" version 2>/dev/null || echo "")
    if [[ -z "$latest_version" ]]; then
        print_error "Could not fetch latest version for $npm_name"
        return 1
    fi

    print_info "Latest version: $latest_version"

    # Update version in file
    sed -i "s/version = \"[^\"]*\"/version = \"$latest_version\"/" "$pkg_file"

    # Update URL hash
    sed -i "s/hash = \"sha256-[^\"]*\"/hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"/" "$pkg_file"

    # If there's a package-lock.json, we need to update it
    if [[ -f "$pkg_dir/package-lock.json" ]]; then
        print_info "Updating package-lock.json..."
        (
            cd "$pkg_dir"
            # Create a temporary package.json
            echo "{\"name\": \"temp\", \"version\": \"1.0.0\", \"dependencies\": {\"$npm_name\": \"$latest_version\"}}" > package.json
            npm install --package-lock-only
            rm package.json
        )

        # Update npmDepsHash
        sed -i "s/npmDepsHash = \"[^\"]*\"/npmDepsHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"/" "$pkg_file"
    fi

    print_info "Building to get correct hashes..."
    if ! nix build -f "$SCRIPT_DIR" "$pkg_name" 2>&1 | tee /tmp/nix-build-output; then
        # Extract both hashes if needed
        local url_hash deps_hash
        url_hash=$(grep -oP 'got:\s+\K[^\s]+' /tmp/nix-build-output | head -1)
        deps_hash=$(grep -oP 'got:\s+\K[^\s]+' /tmp/nix-build-output | tail -1)

        if [[ -n "$url_hash" ]]; then
            sed -i "0,/hash = \"sha256-[^\"]*\"/{s/hash = \"sha256-[^\"]*\"/hash = \"$url_hash\"/}" "$pkg_file"
        fi

        if [[ -f "$pkg_dir/package-lock.json" && -n "$deps_hash" && "$deps_hash" != "$url_hash" ]]; then
            sed -i "s/npmDepsHash = \"[^\"]*\"/npmDepsHash = \"$deps_hash\"/" "$pkg_file"
        fi

        # Try building again
        if nix build -f "$SCRIPT_DIR" "$pkg_name" 2>&1; then
            print_success "Updated $pkg_name to version $latest_version"
        else
            print_error "Failed to update $pkg_name"
            return 1
        fi
    else
        print_success "Package built successfully"
    fi
}

# Function to update a Python package
update_python_package() {
    local pkg_file="$1"
    local pkg_name
    pkg_name="$(basename "$pkg_file" .nix)"

    print_info "Updating Python package: $pkg_name"

    # Check if it's using unstableGitUpdater
    if grep -q "unstableGitUpdater" "$pkg_file"; then
        print_info "Package uses unstableGitUpdater, running nix-update..."
        if command -v nix-update >/dev/null 2>&1; then
            nix-update "$pkg_name" --flake
        else
            print_warning "nix-update not found, skipping $pkg_name"
        fi
        return
    fi

    # For other Python packages, try to extract GitHub info
    local owner repo
    owner=$(grep -oP 'owner = "\K[^"]+' "$pkg_file" || echo "")
    repo=$(grep -oP 'repo = "\K[^"]+' "$pkg_file" || echo "")

    if [[ -n "$owner" && -n "$repo" ]]; then
        update_go_package "$pkg_file"  # Similar process for GitHub-based packages
    else
        print_warning "Could not determine update method for $pkg_name"
    fi
}

# Function to detect package type and update
update_package() {
    local pkg_file="$1"

    if grep -q "buildGoModule" "$pkg_file"; then
        update_go_package "$pkg_file"
    elif grep -q "buildNpmPackage" "$pkg_file"; then
        update_npm_package "$pkg_file"
    elif grep -q "buildPythonApplication\|buildPythonPackage" "$pkg_file"; then
        update_python_package "$pkg_file"
    else
        print_warning "Unknown package type for $(basename "$pkg_file")"
    fi
}

# Function to list all packages
list_packages() {
    print_info "Available packages:"
    for pkg in "$PKGS_DIR"/*.nix "$PKGS_DIR"/*/default.nix; do
        if [[ -f "$pkg" ]]; then
            local name
            name=$(basename "$(dirname "$pkg")")
            if [[ "$name" == "pkgs" ]]; then
                name=$(basename "$pkg" .nix)
            fi
            echo "  - $name"
        fi
    done
}

# Main function
main() {
    local package_name=""
    local no_commit=false
    local list_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "Usage: $0 [OPTIONS] [PACKAGE_NAME]"
                echo ""
                echo "Update custom packages in the pkgs directory"
                echo ""
                echo "Options:"
                echo "  -h, --help      Show this help message"
                echo "  -l, --list      List available packages"
                echo "  -n, --no-commit Don't create backup commit"
                echo ""
                echo "Examples:"
                echo "  $0              Update all packages"
                echo "  $0 opencode     Update only opencode package"
                echo "  $0 --list       List all available packages"
                exit 0
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -n|--no-commit)
                no_commit=true
                shift
                ;;
            *)
                package_name="$1"
                shift
                ;;
        esac
    done

    # Check if we're in a git repo
    check_git

    # List packages if requested
    if [[ "$list_only" == true ]]; then
        list_packages
        exit 0
    fi

    # Create backup commit unless disabled
    if [[ "$no_commit" == false ]]; then
        create_backup_commit
    fi

    # Update packages
    if [[ -n "$package_name" ]]; then
        # Update specific package
        local found=false

        # Check direct .nix file
        if [[ -f "$PKGS_DIR/$package_name.nix" ]]; then
            update_package "$PKGS_DIR/$package_name.nix"
            found=true
        # Check for directory with default.nix
        elif [[ -f "$PKGS_DIR/$package_name/default.nix" ]]; then
            update_package "$PKGS_DIR/$package_name/default.nix"
            found=true
        fi

        if [[ "$found" == false ]]; then
            print_error "Package '$package_name' not found"
            list_packages
            exit 1
        fi
    else
        # Update all packages
        print_info "Updating all packages..."

        # Process direct .nix files
        for pkg in "$PKGS_DIR"/*.nix; do
            if [[ -f "$pkg" && "$(basename "$pkg")" != "overlay.nix" ]]; then
                update_package "$pkg" || print_warning "Failed to update $(basename "$pkg" .nix)"
            fi
        done

        # Process directories with default.nix
        for dir in "$PKGS_DIR"/*/; do
            if [[ -f "$dir/default.nix" ]]; then
                update_package "$dir/default.nix" || print_warning "Failed to update $(basename "$dir")"
            fi
        done
    fi

    print_success "Update process completed!"

    # Show git status
    if [[ -n $(git status --porcelain) ]]; then
        print_info "Changes made:"
        git status --short
        echo ""
        print_info "To revert all changes: git reset --hard HEAD"
        print_info "To commit changes: git add -A && git commit -m 'chore: update packages'"
    else
        print_info "No changes were made"
    fi
}

# Run main function
main "$@"
