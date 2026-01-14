{ config, pkgs, ... }:
with builtins;
let
  cfg = config.omarchy;

  themeFile = path { path = ../../../themes/${cfg.theme}/hyprlock.conf; };
in
{
  programs.hyprlock = {
    enable = true;
    settings = { };
  };

  xdg.configFile."hypr/hyprlock.conf".source =
    pkgs.replaceVars (path { path = ../../../config/hypr/hyprlock.conf; })
      {
        inherit themeFile;
        font = cfg.font.name;
      };
}
