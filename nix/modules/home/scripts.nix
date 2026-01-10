{
  cfg,
  lib,
  pkgs,
  inputs,
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  flakes = {
    # walker comes from flake, nixpkgs is too old and doesn't even have elephant
    walker = inputs.walker.packages.${system}.default;

    # tte is too old in nixpkgs
    tte = inputs.terminaltexteffects.packages.${system}.default;
  };

  createScript =
    name: vars:
    let
      script = pkgs.replaceVars ../../../bin/${name} vars;
    in
    pkgs.runCommand name { } ''
      install -Dm 755 ${script} $out/bin/${name}
    '';

  omarchy-restart-waybar = createScript "omarchy-restart-waybar" (
    with pkgs;
    {
      inherit
        bash
        procps
        uwsm
        waybar
        ;
    }
  );
in
{
  scripts = { inherit omarchy-restart-waybar; };

  allScripts = [
    (createScript "omarchy-cmd-present" (with pkgs; { inherit bash; }))
    (createScript "omarchy-cmd-screenrecord" (
      with pkgs;
      {
        inherit
          bash
          ffmpeg
          gpu-screen-recorder
          hyprland
          jq
          libnotify
          v4l-utils
          ;
      }
    ))
    (createScript "omarchy-cmd-screensaver" (
      with pkgs;
      {
        inherit bash hyprland jq;
        inherit (flakes) tte;
        screensaverText = ../../../logo.txt;
      }
    ))
    (createScript "omarchy-cmd-screenshot" (
      with pkgs;
      {
        inherit
          bash
          grim
          hyprland
          jq
          satty
          slurp
          wayfreeze
          wl-clipboard
          ;
      }
    ))
    (createScript "omarchy-cmd-share" (
      with pkgs;
      {
        inherit
          bash
          fzf
          gnugrep
          localsend
          wl-clipboard
          ;
      }
    ))
    (createScript "omarchy-font-current" (with pkgs; { inherit bash gnugrep; }))
    (createScript "omarchy-font-list" (with pkgs; { inherit bash fontconfig gnugrep; }))
    (createScript "omarchy-font-set" (
      with pkgs;
      {
        inherit
          bash
          fontconfig
          gnugrep
          libnotify
          ;
      }
    ))
    (createScript "omarchy-launch-about" (with pkgs; { inherit bash fastfetch; }))
    (createScript "omarchy-launch-bluetooth" (with pkgs; { inherit bash bluetui; }))
    (createScript "omarchy-launch-editor" (with pkgs; { inherit bash uwsm; }))
    (createScript "omarchy-launch-floating-terminal-with-presentation" (
      with pkgs; { inherit bash uwsm xdg-terminal-exec; }
    ))
    (createScript "omarchy-launch-or-focus" (
      with pkgs;
      {
        inherit
          bash
          hyprland
          jq
          uwsm
          ;
      }
    ))
    (createScript "omarchy-launch-or-focus-tui" (with pkgs; { inherit bash; }))
    (createScript "omarchy-launch-or-focus-webapp" (with pkgs; { inherit bash; }))
    (createScript "omarchy-launch-screensaver" (
      with pkgs;
      {
        inherit
          bash
          hyprland
          jq
          libnotify
          xdg-terminal-exec
          ;
        inherit (flakes) walker;
        alacrittyConf = ../../../default/alacritty/screensaver.toml;
        ghosttyConf = ../../../default/ghostty/screensaver;
      }
    ))
    (createScript "omarchy-launch-tui" (with pkgs; { inherit bash uwsm xdg-terminal-exec; }))
    (createScript "omarchy-launch-walker" (
      with pkgs;
      {
        inherit bash uwsm;
        inherit (flakes) walker;
      }
    ))
    (createScript "omarchy-launch-webapp" (
      with pkgs;
      {
        inherit bash xdg-utils uwsm;
        inherit (cfg) browser;
      }
    ))
    (createScript "omarchy-launch-wifi" (with pkgs; { inherit bash impala; }))
    (createScript "omarchy-lock-screen" (with pkgs; { inherit bash hyprland hyprlock; }))
    (createScript "omarchy-menu" (
      with pkgs;
      {
        inherit
          bash
          hyprpicker
          libnotify
          power-profiles-daemon
          wiremix
          xdg-terminal-exec
          ;
        inherit (flakes) walker;
      }
    ))
    (createScript "omarchy-menu-keybindings" (
      with pkgs;
      {
        inherit
          bash
          bc
          gawk
          gnused
          hyprland
          jq
          libxkbcommon
          ;
      }
    ))
    (createScript "omarchy-notification-dismiss" (
      with pkgs;
      {
        inherit
          bash
          gnugrep
          gnused
          mako
          ;
      }
    ))
    (createScript "omarchy-powerprofiles-list" (
      with pkgs; { inherit bash gawk power-profiles-daemon; }
    ))
    (createScript "omarchy-restart-app" (with pkgs; { inherit bash uwsm; }))
    (createScript "omarchy-restart-hypridle" (with pkgs; { inherit bash; }))
    (createScript "omarchy-restart-hyprsunset" (with pkgs; { inherit bash; }))
    (createScript "omarchy-restart-swayosd" (with pkgs; { inherit bash; }))
    (createScript "omarchy-restart-walker" (with pkgs; { inherit bash; }))
    omarchy-restart-waybar
    (createScript "omarchy-setup-dns" (with pkgs; { inherit bash gum libnotify; }))
    (createScript "omarchy-show-done" (with pkgs; { inherit bash gum; }))
    (createScript "omarchy-show-logo" (
      with pkgs;
      {
        inherit bash;
        logo = ../../../logo.txt;
      }
    ))
    (createScript "omarchy-theme-bg-next" (
      with pkgs;
      {
        inherit
          bash
          findutils
          libnotify
          swaybg
          uwsm
          ;
        backgroundsDir = ../../../themes/${cfg.theme}/backgrounds;
      }
    ))
    (createScript "omarchy-toggle-idle" (
      with pkgs;
      {
        inherit
          bash
          hypridle
          libnotify
          uwsm
          ;
      }
    ))
    (createScript "omarchy-toggle-nightlight" (
      with pkgs;
      {
        inherit
          bash
          gnugrep
          hyprland
          hyprsunset
          libnotify
          ;
      }
    ))
    (createScript "omarchy-toggle-screensaver" (with pkgs; { inherit bash libnotify; }))
    (createScript "omarchy-toggle-waybar" (with pkgs; { inherit bash uwsm waybar; }))
    (createScript "omarchy-tz-select" (
      with pkgs;
      {
        inherit bash gnused gum;
        CONFIG_FILE = "redo this implementation";
      }
    ))
  ];
}
