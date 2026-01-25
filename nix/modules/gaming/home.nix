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
  gaming = osConfig.omarchy.gaming or null;
in
mkIf (cfg.enable && gaming != null && gaming.heroicGameLauncher) {
  home.packages = [ p.heroic ];
}
