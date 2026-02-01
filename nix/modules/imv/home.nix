{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib) getExe getExe';
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;
  p = cfg._packages;
in
mkIf (p.imv != null) {
  programs.imv.enable = true;

  xdg.configFile."imv/config".source =
    pkgs.replaceVars (path { path = ../../../config/imv/config; })
      {
        mogrify = getExe' p.imagemagick "mogrify";
        satty = getExe p.satty;
      };
}
