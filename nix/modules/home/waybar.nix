{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;

  clockFormat = if cfg.twelveHourClock then "{:L%A %I:%M %p}" else "{:L%A %H:%M}";

  inherit
    (import ./scripts.nix {
      inherit
        cfg
        inputs
        lib
        pkgs
        ;
    })
    scripts
    ;

  indicatorSource = ../../../default/waybar/indicators/screen-recording.sh;
  screen-recording-indicator = pkgs.writeShellScript "screen-recording-wrapped" ''
    exec ${pkgs.bash}/bin/bash ${indicatorSource} "$@"
  '';

  waybarCss = ../../../themes/${config.omarchy.theme}/waybar.css;
in
lib.mkIf cfg.enable {
  programs.waybar = {
    enable = true;
  };

  xdg.configFile = {
    "waybar/config.jsonc" = {
      source = pkgs.replaceVars ../../../config/waybar/config.jsonc (
        with pkgs;
        {
          inherit
            alacritty
            clockFormat
            pamixer
            screen-recording-indicator
            wiremix
            xdg-terminal-exec
            ;
        }
      );
      onChange = "${scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
    "waybar/style.css".source = ../../../config/waybar/style.css;
    "omarchy/current/theme/waybar.css" = {
      source = waybarCss;
      onChange = "${scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
  };
}
