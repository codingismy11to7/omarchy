{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib) getExe getExe';
  p = config.omarchy._packages;
in
{
  programs.imv.enable = true;

  xdg.configFile."imv/config".source =
    pkgs.replaceVars (path { path = ../../../config/imv/config; })
      {
        mogrify = getExe' p.imagemagick "mogrify";
        satty = getExe p.satty;
      };
}
