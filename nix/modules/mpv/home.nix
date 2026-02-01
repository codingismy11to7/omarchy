{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;
in
mkIf (cfg._packages.mpv != null) {
  programs.mpv = {
    enable = true;
    package = cfg._packages.mpv;
  };
}
