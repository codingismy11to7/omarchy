{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;

  clockFormat = if cfg.twelveHourClock then "{:L%A %I:%M %p}" else "{:L%A %H:%M}";

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
      source = pkgs.replaceVars ../../../config/waybar/config.jsonc {
        font = cfg.font.name;
        inherit clockFormat screen-recording-indicator;
        inherit (pkgs)
          alacritty
          pamixer
          wiremix
          xdg-terminal-exec
          ;
      };
      onChange = "${cfg.scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
    "waybar/style.css".source = ../../../config/waybar/style.css;
    "omarchy/current/theme/waybar.css" = {
      source = waybarCss;
      onChange = "${cfg.scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
  };
}
