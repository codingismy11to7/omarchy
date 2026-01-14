{
  config,
  omarchyInputs,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;

  inherit (pkgs.stdenv.hostPlatform) system;

  themeFile = path { path = ../../../themes/${cfg.theme}/hyprland-preview-share-picker.css; };
in
{
  home.packages = [
    omarchyInputs.hyprland-preview-share-picker.packages.${system}.default
  ];

  xdg.configFile."hyprland-preview-share-picker/config.yaml".source =
    pkgs.replaceVars (path { path = ../../../config/hyprland-preview-share-picker/config.yaml; })
      {
        inherit (pkgs) slurp;
        inherit themeFile;
      };
}
