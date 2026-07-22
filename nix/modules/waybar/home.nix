{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  p = cfg._packages;

  clockFormat = if cfg.twelveHourClock then "{:L%A %I:%M %p}" else "{:L%A %H:%M}";

  indicatorSource = path { path = ../../../default/waybar/indicators/screen-recording.sh; };
  screen-recording-indicator = pkgs.writeShellScript "screen-recording-wrapped" ''
    exec ${p.bash}/bin/bash ${indicatorSource} "$@"
  '';

  waybarCss = pkgs.replaceVars (path { path = ../../../default/themed/waybar.css.tpl; }) {
    inherit (config.omarchy.palette) foreground background;
  };
in
lib.mkIf cfg.hyprland.enable {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile = {
    "waybar/config.jsonc" = {
      source = pkgs.replaceVars (path { path = ../../../config/waybar/config.jsonc; }) {
        font = cfg.font.name;
        inherit clockFormat screen-recording-indicator;
        alacritty = lib.getExe p.alacritty;
        pamixer = lib.getExe p.pamixer;
        xdg-terminal-exec = lib.getExe p.xdg-terminal-exec;
        notify-send = lib.getExe p.libnotify;
      };
      onChange = "${cfg.scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
    "waybar/style.css".source = path { path = ../../../config/waybar/style.css; };
    "omarchy/current/theme/waybar.css" = {
      source = waybarCss;
      onChange = "${cfg.scripts.omarchy-restart-waybar}/bin/omarchy-restart-waybar";
    };
  };
}
