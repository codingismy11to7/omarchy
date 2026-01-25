# Omarchy Module Patterns

## Centralized Options
Options are defined centrally, NOT in individual modules:

- **Home-manager options**: Define in `nix/modules/options/home.nix` under `options.omarchy`
- **NixOS options**: Define in `nix/modules/nixos.nix` under `options.omarchy`

Individual modules (like `nix/modules/bash/home.nix` or `nix/modules/bash/core.nix`) should only contain `config` blocks wrapped in `lib.mkIf`, not `options` definitions. Module structure is `nix/modules/<name>/home.nix` for home-manager and `nix/modules/<name>/core.nix` for NixOS-level.

## Example: Adding a new feature
```nix
# In options/home.nix - add the option
myFeature = {
  enable = mkEnableOption "My feature description" // {
    default = true;  # if should default to enabled
  };
};

# In myfeature/home.nix - only config, no options
lib.mkIf (cfg.enable && cfg.myFeature.enable) {
  # configuration here
}
```

## Package Management
All packages go through the centralized `omarchy.packages` / `omarchy._packages` system so users can override or disable them:

1. **Add to defaults** in `nix/modules/options/home.nix` inside the `defaults` attrset of `_packages`:
   ```nix
   defaults = {
     inherit (pkgs)
       # ...existing packages...
       my-new-package
       ;
   };
   ```

2. **Reference via `cfg._packages`** in modules — never use `pkgs.foo` directly for packages that should be overridable:
   ```nix
   # CORRECT - uses overridable package
   services.gnome-keyring.package = cfg._packages.gnome-keyring;
   home.packages = [ cfg._packages.my-new-package ];

   # WRONG - bypasses the override system
   services.gnome-keyring.package = pkgs.gnome-keyring;
   home.packages = [ pkgs.my-new-package ];
   ```

3. **Users can override** any package: `omarchy.packages.gnome-keyring = pkgs.some-alternative;`
4. **Users can disable** any package: `omarchy.packages.gnome-keyring = null;`

## File Installation Patterns
- User files: `home.file.".bashrc".source = ...`
- XDG data files: `xdg.dataFile."omarchy/default/...".source = ...`
- XDG config files: `xdg.configFile."omarchy/...".source = ...`
