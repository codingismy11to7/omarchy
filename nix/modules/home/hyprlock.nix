{ config, pkgs, ... }:
let
  cfg = config.omarchy;

  themeFile = ../../../themes/${cfg.theme}/hyprlock.conf;
in
{
  programs.hyprlock = {
    enable = true;
    settings = { };
  };

  xdg.configFile."hypr/hyprlock.conf".source = pkgs.replaceVars ../../../config/hypr/hyprlock.conf {
    inherit themeFile;
    font = cfg.font.name;
  };
}
