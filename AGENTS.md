# AGENTS.md - NixOS Flake Repository Guidelines

## Build/Test Commands
- **Build system**: `nix build .#nixosConfigurations.{hostname}.config.system.build.toplevel`
- **Build home config**: `nix build .#homeConfigurations.{user}@{hostname}.activationPackage`
- **Check flake**: `nix flake check`
- **Format code**: `alejandra .` (Nix formatter included in flake)
- **Deploy**: `deploy .#pattern` or `deploy .#archive` (via deploy-rs)
- **Dev shell**: `nix develop` (includes deploy-rs tools)
- **Update packages**: `nix run .#update-packages` (updates custom packages in pkgs/)

## Code Style Guidelines
- **Nix formatting**: Use alejandra formatter (enforced)
- **File structure**: Modules in `modules/`, hosts in `hosts/`, packages in `pkgs/`
- **Imports**: Use `{pkgs, lib, config, ...}:` pattern, with `with lib;` when needed
- **Module options**: Define with `mkEnableOption`, `mkOption`, use `mkIf`/`mkMerge` for conditionals
- **Naming**: camelCase for variables, kebab-case for filenames, PascalCase for NixOS modules
- **Overlays**: Define in `pkgs/overlay.nix`, apply via flake overlays
- **Error handling**: Use `assert` for preconditions, `lib.optional` for conditional lists
- **Comments**: Minimal, only for non-obvious logic or TODOs
- **Flake inputs**: Follow existing patterns, use `.follows` to reduce duplication
- **Linting**: ALWAYS fix linting issues properly - never disable linters/checkers as workarounds