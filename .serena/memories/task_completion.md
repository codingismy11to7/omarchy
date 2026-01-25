# Task Completion Checklist

## Before Committing
1. Run `nix flake check` to validate the configuration builds
2. Run `nix fmt` on any modified `.nix` files
3. Run `lint` to check for issues (if in dev shell)

## When Creating New Files
- Immediately `git add` new `.nix` files (flakes only see tracked files)
- New NixOS sub-modules go in `nix/modules/<name>/core.nix` and import from `nixos.nix`
- New home-manager modules go in `nix/modules/<name>/home.nix` and import from `home-manager.nix`

## Commit Guidelines
- Only commit when explicitly requested by user
- Stage specific files rather than `git add -A`
- Never commit sensitive files (.env, credentials)

## Testing on VM
- Use `deploy-vm` skill or manual rsync + `nix flake update omarchy && nh os test .`
- Clear SSH known_hosts if VM was reinstalled: `ssh-keygen -R <ip>`
