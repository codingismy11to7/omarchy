{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isx86_64;

  cfg = config.omarchy;
  p = cfg._packages;
  gaming = osConfig.omarchy.gaming or null;
in
mkIf (cfg.enable && gaming.enable && gaming.heroicGameLauncher && isx86_64) {
  home.packages = [ p.heroic ];
}
