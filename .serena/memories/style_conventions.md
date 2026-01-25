# Code Style and Conventions

## Critical Rules

### Tool Paths: Always Explicit, Never PATH
**NEVER** rely on tools being in PATH. Always substitute full nix store paths into config files using `@variable@` placeholders and `pkgs.replaceVars`.

### Path Literals
Always wrap path literals in `builtins.path { path = ...; }` when using them as file sources.

### Nix Flake Basics
- When creating new `.nix` files, immediately `git add` them (flakes only see git-tracked files)
- The hyprland package comes from a flake input, not nixpkgs - use `cfg.hyprland.package`
- `xdg-desktop-portal-hyprland` must use matching flake version via `portalPackage` options

## Nix Coding Conventions
- Open files using `builtins` with `with builtins;` at top
- Use `inherit (lib) getExe getExe';` at top of let blocks
- Use `inherit (exe) foo bar;` rather than `foo = exe.foo;`
- Use `inherit (cfg) theme;` to pull config values

## Module Patterns
- NixOS modules use `mkIf cfg.enable { ... }` where `cfg = config.omarchy`
- Home-manager modules follow the same pattern
- Terminal modules are mutually exclusive via `mkIf (cfg.terminal == "ghostty")`
- New NixOS sub-modules go in `nix/modules/nixos/`
- New home-manager modules go in `nix/modules/home/`

## Script Placeholder Format
Scripts use `@exe@` placeholders (not `@pkg@/bin/exe`):
```bash
#!@bash@/bin/bash
@jq@ -r '.foo' | @grep@ bar
```
The shebang is the exception — it needs the full path form.

## Patching Upstream Files
**NEVER create new template files** when nixifying existing configs. Modify existing files in `config/` or `default/` to add `@placeholder@` substitutions.
