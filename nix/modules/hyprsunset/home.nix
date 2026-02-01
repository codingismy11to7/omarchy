{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;
in
mkIf cfg.hyprland.enable {
  services.hyprsunset = {
    enable = true;
    settings = { };
  };

  xdg.configFile."hypr/hyprsunset.conf".source = builtins.path {
    path = ../../../config/hypr/hyprsunset.conf;
  };
}
