{ config, ... }:
with builtins;
let
  cfg = config.omarchy;
  configFile = path { path = ../../../themes/${cfg.theme}/mako.ini; };
in
{
  services.mako = {
    enable = true;
    extraConfig = readFile configFile;
  };

  xdg.dataFile."omarchy/default/mako/core.ini".source = path {
    path = ../../../default/mako/core.ini;
  };
}
