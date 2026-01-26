{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;

  cfg = config.omarchy;
  p = cfg._packages;
  gaming = osConfig.omarchy.gaming or { enable = false; };
in
mkIf (cfg.enable && gaming.enable && gaming.heroicGameLauncher) {
  home.packages = [ p.heroic ];
}
