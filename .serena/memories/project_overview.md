# Omarchy Project Overview

## Purpose
Omarchy on NixOS reproduces the Omarchy desktop experience as Nix flake modules. It exports `nixosModules`, `homeManagerModules`, and a `lazyvimTheme` for consumers.

## Critical: Reuse Over Reimplementation
This fork exists as a **rebasing fork** on top of upstream basecamp/omarchy. Every upstream rebase requires manual review of conflicts. Therefore:
- **Always reuse upstream scripts and config files** rather than reimplementing their logic in Nix
- Use `builtins.path`, `pkgs.replaceVars`, or `bash <script>` to reference upstream files directly
- Only add Nix-specific wrappers (guards, conditionals, activation hooks) around upstream code
- Reimplementations create hidden divergence that silently breaks on rebase — the Nix module should be a thin layer over upstream, not a parallel implementation

## Tech Stack
- **Nix/NixOS** - Declarative system configuration
- **Home Manager** - User environment management
- **Hyprland** - Wayland compositor (from flake input, not nixpkgs)
- **Bash** - Scripts in `bin/` directory

## Project Structure
- `nix/modules/nixos.nix` - System-level module (hyprland, evince, nautilus, Qt theming)
- `nix/modules/home-manager.nix` - Core home-manager module
- `nix/modules/options/home.nix` - Central options definition
- `nix/modules/<name>/home.nix` - Individual app modules (hyprland, waybar, walker, mako, gtk, scripts, etc.)
- `nix/modules/nixos/*.nix` - NixOS sub-modules (sddm, gaming, qt)
- `default/` - Template configs with `@variable@` placeholders
- `config/` - User-editable overrides (sourced after defaults)
- `themes/{name}/colors.toml` - Palette definitions
- `bin/` - 40+ `omarchy-*` scripts

## Configuration Layers
1. `default/` - Template configs with `@variable@` placeholders, processed by `pkgs.replaceVars`
2. `config/` - User-editable overrides, sourced last so they win
3. `themes/{name}/colors.toml` - Hex palette injected into `.tpl` template files

## Package Overrides
Users can override any package used by omarchy via `omarchy.packages`:
```nix
omarchy.packages = {
  jq = pkgs.jaq;  # Use jaq instead of jq
  brave = pkgs.ungoogled-chromium;  # Use different browser
};
```
Internally, modules use `cfg._packages.*` which merges user overrides with defaults (~50 packages).
