{ config, pkgs, ... }:
let
  cfg = config.omarchy;

  themeCss = ../../../themes/${cfg.theme}/swayosd.css;
in
{
  services.swayosd.enable = true;

  xdg.configFile."swayosd/config.toml".source = ../../../config/swayosd/config.toml;
  xdg.configFile."swayosd/style.css".source = pkgs.replaceVars ../../../config/swayosd/style.css {
    inherit themeCss;
    font = cfg.font.name;
  };
}
