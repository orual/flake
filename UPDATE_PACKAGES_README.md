# Package Update Script

The `update-packages.sh` script automates updating custom packages in the `pkgs/` directory.

## Features

- Automatically detects package type (Go, NPM, Python)
- Creates backup git commits before updates
- Updates package versions and hashes automatically
- Supports updating all packages or specific ones
- Easy rollback with git

## Usage

```bash
# Enter dev shell for required tools
nix develop

# List all available packages
./update-packages.sh --list

# Update all packages
./update-packages.sh

# Update a specific package
./update-packages.sh opencode

# Update without creating backup commit
./update-packages.sh --no-commit claude-code

# Show help
./update-packages.sh --help
```

## How it works

1. **Go packages**: Fetches latest GitHub release/tag, updates version and hash
2. **NPM packages**: Gets latest version from npm registry, updates package-lock.json if present
3. **Python packages**: Uses nix-update for unstable packages, or GitHub releases for others

## Reverting changes

```bash
# Revert all uncommitted changes
git reset --hard HEAD

# Revert to backup commit
git reset --hard HEAD~1
```

## Adding support for new package types

Edit `update-packages.sh` and add a new update function following the existing patterns.