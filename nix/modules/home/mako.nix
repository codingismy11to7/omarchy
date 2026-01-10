{ config, ... }:
with builtins;
let
  configFile = ../../../themes/${config.omarchy.theme}/mako.ini;
in
{
  services.mako = {
    enable = true;
    extraConfig = readFile configFile;
  };

  xdg.dataFile."omarchy/default/mako/core.ini".source = ../../../default/mako/core.ini;
}
