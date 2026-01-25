# Suggested Commands

## Build & Test
- `nix flake check` - Validates entire configuration by building a test NixOS system with omarchy enabled
- `nix fmt <files>` - Format nix files (uses nixfmt)
- `dev-mode` - File watcher that auto-runs `nix flake check` on changes (available in `nix develop`)
- `lint` / `lint --fix` - Run statix and deadnix linting (available in `nix develop`)

## Git
- `git status` - Check working tree status
- `git diff` - View changes
- `git add <files>` - Stage specific files (prefer over `git add -A`)
- `git commit -m "message"` - Create commit

## System Utilities
- `ls` - List directory contents
- `find` - Search for files
- `grep` / `rg` - Search file contents
- `cat` / `head` / `tail` - Read files

## Development Shell
Enter the development shell with `nix develop` to get access to:
- `dev-mode` - Auto-run flake check on changes
- `lint` - Run statix and deadnix
