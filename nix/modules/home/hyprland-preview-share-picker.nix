{
  config,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;

  inherit (pkgs.stdenv.hostPlatform) system;

  themeFile = ../../../themes/${cfg.theme}/hyprland-preview-share-picker.css;
in
{
  home.packages = [
    inputs.hyprland-preview-share-picker.packages.${system}.default
  ];

  xdg.configFile."hyprland-preview-share-picker/config.yaml".source =
    pkgs.replaceVars ../../../config/hyprland-preview-share-picker/config.yaml
      {
        inherit (pkgs) slurp;
        inherit themeFile;
      };
}
