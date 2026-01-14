{
  config,
  lib,
  pkgs,
  omarchyInputs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  hyprland = cfg.hyprland.package;

  inherit (pkgs.stdenv.hostPlatform) system;

  flakes = {
    # walker comes from flake, nixpkgs is too old and doesn't even have elephant
    walker = omarchyInputs.walker.packages.${system}.default;

    # tte is too old in nixpkgs
    tte = omarchyInputs.terminaltexteffects.packages.${system}.default;
  };

  createScript =
    name: vars:
    let
      orig = path {
        inherit name;
        path = ../../../bin/${name};
      };
      script = pkgs.replaceVars orig vars;
    in
    pkgs.runCommand name { } ''
      install -Dm 755 ${script} $out/bin/${name}
    '';

  omarchy-restart-waybar = createScript "omarchy-restart-waybar" {
    inherit (pkgs)
      bash
      procps
      uwsm
      waybar
      ;
  };

  welcomeDotSh = pkgs.replaceVars (path { path = ../../../install/first-run/welcome.sh; }) {
    inherit (pkgs) libnotify;
  };
  wifiDotSh = pkgs.replaceVars (path { path = ../../../install/first-run/wifi.sh; }) {
    inherit (pkgs) libnotify;
  };

  allScripts = [
    (createScript "omarchy-cmd-audio-switch" {
      inherit (pkgs)
        bash
        gnugrep
        gnused
        jq
        pulseaudio
        swayosd
        wireplumber
        ;
      inherit hyprland;
    })
    (createScript "omarchy-cmd-first-run" {
      inherit (cfg) firstRunMode;
      inherit (pkgs) bash;
      inherit welcomeDotSh wifiDotSh;
    })
    (createScript "omarchy-cmd-present" { inherit (pkgs) bash; })
    (createScript "omarchy-cmd-screenrecord" {
      inherit (pkgs)
        bash
        ffmpeg
        gpu-screen-recorder
        jq
        libnotify
        v4l-utils
        ;
      inherit hyprland;
    })
    (createScript "omarchy-cmd-screensaver" {
      inherit (pkgs) bash jq;
      inherit hyprland;
      inherit (flakes) tte;
      screensaverText = path { path = ../../../logo.txt; };
    })
    (createScript "omarchy-cmd-screenshot" {
      inherit (pkgs)
        bash
        grim
        jq
        satty
        slurp
        wayfreeze
        wl-clipboard
        ;
      inherit hyprland;
    })
    (createScript "omarchy-cmd-share" {
      inherit (pkgs)
        bash
        fzf
        gnugrep
        localsend
        wl-clipboard
        ;
    })
    (createScript "omarchy-font-current" { inherit (pkgs) bash gnugrep; })
    (createScript "omarchy-font-list" { inherit (pkgs) bash fontconfig gnugrep; })
    (createScript "omarchy-font-set" {
      inherit (pkgs)
        bash
        fontconfig
        gnugrep
        libnotify
        ;
    })
    (createScript "omarchy-hyprland-window-close-all" {
      inherit (pkgs) bash jq;
      inherit hyprland;
    })
    (createScript "omarchy-hyprland-window-pop" {
      inherit (pkgs) bash jq;
      inherit hyprland;
    })
    (createScript "omarchy-hyprland-workspace-toggle-gaps" {
      inherit (pkgs) bash jq;
      inherit hyprland;
      gapsOut = if cfg.hyprland.widerWindowGaps then "20" else "10";
      gapsIn = if cfg.hyprland.widerWindowGaps then "10" else "5";
      rounding = if cfg.hyprland.roundWindowCorners then "8" else "0";
    })
    (createScript "omarchy-launch-about" { inherit (pkgs) bash fastfetch; })
    (createScript "omarchy-launch-bluetooth" { inherit (pkgs) bash bluetui; })
    (createScript "omarchy-launch-editor" { inherit (pkgs) bash uwsm; })
    (createScript "omarchy-launch-floating-terminal-with-presentation" {
      inherit (pkgs) bash uwsm xdg-terminal-exec;
    })
    (createScript "omarchy-launch-or-focus" {
      inherit (pkgs)
        bash
        jq
        uwsm
        ;
      inherit hyprland;
    })
    (createScript "omarchy-launch-or-focus-tui" { inherit (pkgs) bash; })
    (createScript "omarchy-launch-or-focus-webapp" { inherit (pkgs) bash; })
    (createScript "omarchy-launch-browser" {
      inherit (pkgs) bash uwsm xdg-utils;
      inherit (cfg) browser;
    })
    (createScript "omarchy-launch-screensaver" {
      inherit (pkgs)
        bash
        jq
        libnotify
        xdg-terminal-exec
        ;
      inherit hyprland;
      inherit (flakes) walker;
      alacrittyConf = path { path = ../../../default/alacritty/screensaver.toml; };
      ghosttyConf = path { path = ../../../default/ghostty/screensaver; };
    })
    (createScript "omarchy-launch-tui" { inherit (pkgs) bash uwsm xdg-terminal-exec; })
    (createScript "omarchy-launch-walker" {
      inherit (pkgs) bash uwsm;
      inherit (flakes) walker;
    })
    (createScript "omarchy-launch-webapp" {
      inherit (pkgs) bash xdg-utils uwsm;
      inherit (cfg) browser;
    })
    (createScript "omarchy-launch-wifi" { inherit (pkgs) bash impala; })
    (createScript "omarchy-lock-screen" {
      inherit (pkgs) bash hyprlock;
      inherit hyprland;
    })
    (createScript "omarchy-menu" {
      inherit (pkgs)
        bash
        hyprpicker
        libnotify
        power-profiles-daemon
        nautilus
        wiremix
        xdg-terminal-exec
        ;
      inherit (flakes) walker;
    })
    (createScript "omarchy-menu-keybindings" {
      inherit (pkgs)
        bash
        bc
        gawk
        gnused
        jq
        libxkbcommon
        ;
      inherit hyprland;
    })
    (createScript "omarchy-notification-dismiss" {
      inherit (pkgs)
        bash
        gnugrep
        gnused
        mako
        ;
    })
    (createScript "omarchy-pkg-install" {
      inherit (pkgs)
        bash
        fzf
        gawk
        gnused
        jq
        ;
    })
    (createScript "omarchy-pkg-remove" {
      inherit (pkgs)
        bash
        fzf
        jq
        ;
    })
    (createScript "omarchy-powerprofiles-list" { inherit (pkgs) bash gawk power-profiles-daemon; })
    (createScript "omarchy-restart-app" { inherit (pkgs) bash uwsm; })
    (createScript "omarchy-restart-hypridle" { inherit (pkgs) bash; })
    (createScript "omarchy-restart-hyprsunset" { inherit (pkgs) bash; })
    (createScript "omarchy-restart-swayosd" { inherit (pkgs) bash; })
    (createScript "omarchy-restart-walker" { inherit (pkgs) bash; })
    omarchy-restart-waybar
    (createScript "omarchy-setup-dns" { inherit (pkgs) bash gum libnotify; })
    (createScript "omarchy-show-done" { inherit (pkgs) bash gum; })
    (createScript "omarchy-show-logo" {
      inherit (pkgs) bash;
      logo = path { path = ../../../logo.txt; };
    })
    (createScript "omarchy-theme-bg-next" {
      inherit (pkgs)
        bash
        findutils
        libnotify
        swaybg
        uwsm
        ;
      backgroundsDir = path { path = ../../../themes/${cfg.theme}/backgrounds; };
    })
    (createScript "omarchy-toggle-idle" {
      inherit (pkgs)
        bash
        hypridle
        libnotify
        uwsm
        ;
    })
    (createScript "omarchy-toggle-nightlight" {
      inherit (pkgs)
        bash
        gnugrep
        hyprsunset
        libnotify
        ;
      inherit hyprland;
    })
    (createScript "omarchy-toggle-screensaver" { inherit (pkgs) bash libnotify; })
    (createScript "omarchy-toggle-waybar" { inherit (pkgs) bash uwsm waybar; })
    (createScript "omarchy-tz-select" {
      inherit (pkgs) bash gnused gum;
      CONFIG_FILE = "redo this implementation";
    })
  ];
in
{
  options.omarchy.scripts = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Internal access to omarchy scripts";
  };

  config = {
    omarchy.scripts = {
      inherit omarchy-restart-waybar;
    };
    home.packages = allScripts;
  };
}
