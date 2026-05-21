{
  config,
  lib,
  pkgs,
  omarchyInputs,
  ...
}:
with builtins;
let
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;
  hyprland = cfg.hyprland.package;
  p = cfg._packages;

  inherit (lib) getExe getExe';
  inherit (pkgs.stdenv.hostPlatform) system isx86_64;

  flakes = {
    # walker comes from flake, nixpkgs is too old and doesn't even have elephant
    walker = omarchyInputs.walker.packages.${system}.default;

    # tte is too old in nixpkgs
    tte = omarchyInputs.terminaltexteffects.packages.${system}.default;
  };

  # Executables for script substitution
  exe = {
    # Packages with mainProgram
    awk = getExe p.gawk;
    bc = getExe p.bc;
    bluetui = getExe p.bluetui;
    brotli = getExe p.brotli;
    fastfetch = getExe p.fastfetch;
    fzf = getExe p.fzf;
    grep = getExe p.gnugrep;
    grim = getExe p.grim;
    gum = getExe p.gum;
    hypridle = getExe p.hypridle;
    hyprlock = getExe p.hyprlock;
    hyprpicker = getExe p.hyprpicker;
    hyprsunset = getExe p.hyprsunset;
    impala = getExe' p.impala "impala";
    jaq = getExe p.jaq;
    jq = getExe p.jq;
    mpv = getExe p.mpv;
    notify-send = getExe p.libnotify;
    satty = getExe p.satty;
    sed = getExe p.gnused;
    slurp = getExe p.slurp;
    swaybg = getExe p.swaybg;
    tte = getExe flakes.tte;
    walker = getExe flakes.walker;
    waybar = getExe p.waybar;
    wiremix = getExe p.wiremix;
    xdg-terminal-exec = getExe p.xdg-terminal-exec;

    # Packages needing specific binary or getExe'
    bash = "${p.bash}/bin/bash";
    fc-list = "${p.fontconfig}/bin/fc-list";
    ffmpeg = "${p.ffmpeg}/bin/ffmpeg";
    ffplay = "${p.ffmpeg}/bin/ffplay";
    ffprobe = "${p.ffmpeg}/bin/ffprobe";
    find = "${p.findutils}/bin/find";
    hyprctl = getExe' hyprland "hyprctl";
    localsend_app = "${p.localsend}/bin/localsend_app";
    makoctl = "${p.mako}/bin/makoctl";
    pactl = "${p.pulseaudio}/bin/pactl";
    pgrep = "${p.procps}/bin/pgrep";
    pkill = "${p.procps}/bin/pkill";
    powerprofilesctl = "${p.power-profiles-daemon}/bin/powerprofilesctl";
    socat = "${pkgs.socat}/bin/socat";
    swayosd-client = "${p.swayosd}/bin/swayosd-client";
    systemctl = "${p.systemd}/bin/systemctl";
    uwsm-app = "${p.uwsm}/bin/uwsm-app";
    v4l2-ctl = "${p.v4l-utils}/bin/v4l2-ctl";
    wl-copy = "${p.wl-clipboard}/bin/wl-copy";
    wl-paste = "${p.wl-clipboard}/bin/wl-paste";
    wpctl = "${p.wireplumber}/bin/wpctl";
    xdg-settings = "${p.xdg-utils}/bin/xdg-settings";
    xargs = "${p.findutils}/bin/xargs";
    xkbcli = "${p.libxkbcommon}/bin/xkbcli";
  };

  createScript =
    name: vars:
    let
      script = pkgs.replaceVars (path { path = ../../../bin/${name}; }) vars;
    in
    pkgs.runCommand name { } ''
      mkdir -p $out/bin
      echo '#!${pkgs.bash}/bin/bash' > $out/bin/${name}
      cat ${script} >> $out/bin/${name}
      chmod +x $out/bin/${name}
    '';

  omarchy-restart-walker = createScript "omarchy-restart-walker" { };

  omarchy-restart-waybar = createScript "omarchy-restart-waybar" {
    inherit (exe) systemctl;
  };

  omarchy-restart-terminal = createScript "omarchy-restart-terminal" {
    inherit (exe) pgrep pkill;
  };

  omarchy-theme-bg-set = createScript "omarchy-theme-bg-set" {
    inherit (exe)
      pkill
      swaybg
      uwsm-app
      ;
  };

  omarchy-theme-bg-next = createScript "omarchy-theme-bg-next" {
    inherit (exe) find;
    inherit (cfg) theme;
    backgroundsDir = path { path = ../../../themes/${cfg.theme}/backgrounds; };
  };

  omarchy-theme-set-obsidian = createScript "omarchy-theme-set-obsidian" {
    inherit (exe) jq;
  };

  welcomeDotSh = pkgs.replaceVars (path { path = ../../../install/first-run/welcome.sh; }) {
    inherit (p) libnotify;
  };
  wifiDotSh = pkgs.replaceVars (path { path = ../../../install/first-run/wifi.sh; }) {
    inherit (p) libnotify;
  };

  allScripts = [
    (createScript "omarchy-audio-output-switch" {
      inherit (exe)
        grep
        jq
        pactl
        sed
        wpctl
        ;
    })
    (createScript "omarchy-first-run" {
      inherit (cfg) firstRunMode;
      inherit (exe) bash;
      inherit welcomeDotSh wifiDotSh;
    })
    (createScript "omarchy-cmd-present" { })
    (createScript "omarchy-swayosd-client" { })
  ] ++ lib.optional isx86_64 (createScript "omarchy-capture-screenrecording" {
      inherit (exe)
        awk
        ffmpeg
        ffplay
        ffprobe
        grep
        hyprctl
        hyprpicker
        jq
        mpv
        notify-send
        slurp
        v4l2-ctl
        ;
      gpu-screen-recorder = getExe p.gpu-screen-recorder;
    })
  ++ [
    (createScript "omarchy-screensaver" {
      inherit (exe)
        hyprctl
        jq
        tte
        ;
      screensaverText =
        if cfg.screensaver.text != null then
          pkgs.writeText "screensaver.txt" cfg.screensaver.text
        else
          path { path = ../../../logo.txt; };
    })
    (createScript "omarchy-capture-screenshot" {
      inherit (exe)
        grim
        hyprctl
        hyprpicker
        jq
        notify-send
        satty
        slurp
        wl-copy
        ;
    })
    (createScript "omarchy-menu-share" {
      inherit (exe)
        fzf
        grep
        localsend_app
        wl-paste
        ;
    })
    (createScript "omarchy-font-current" {
      inherit (exe) grep;
    })
    (createScript "omarchy-font-list" {
      inherit (exe) fc-list grep;
    })
    (createScript "omarchy-font-set" {
      inherit (exe) fc-list grep notify-send;
    })
    (createScript "omarchy-hook" {
      inherit (exe) bash;
    })
    (createScript "omarchy-hyprland-monitor-focused" {
      inherit (exe) hyprctl jq;
    })
    (createScript "omarchy-hyprland-monitor-watch" {
      inherit (exe) socat;
    })
    (createScript "omarchy-hyprland-window-close-all" {
      inherit (exe) hyprctl jq;
    })
    (createScript "omarchy-hyprland-window-gaps-toggle" {
      inherit (exe) awk hyprctl jq;
      gapsOut = if cfg.hyprland.widerWindowGaps then "20" else "10";
      gapsIn = if cfg.hyprland.widerWindowGaps then "10" else "5";
    })
    (createScript "omarchy-hyprland-window-pop" {
      inherit (exe) hyprctl jq;
    })
    (createScript "omarchy-hyprland-window-transparency-toggle" {
      inherit (exe) hyprctl jq;
    })
    (createScript "omarchy-launch-about" {
      inherit (exe) bash fastfetch;
    })
    (createScript "omarchy-launch-audio" {
      inherit (exe) wiremix;
    })
    (createScript "omarchy-launch-bluetooth" {
      inherit (exe) bluetui;
    })
    (createScript "omarchy-launch-editor" {
      inherit (exe) uwsm-app;
    })
    (createScript "omarchy-launch-floating-terminal-with-presentation" {
      inherit (exe) bash uwsm-app xdg-terminal-exec;
    })
    (createScript "omarchy-launch-or-focus" {
      inherit (exe)
        hyprctl
        jq
        uwsm-app
        ;
    })
    (createScript "omarchy-launch-or-focus-tui" { })
    (createScript "omarchy-launch-or-focus-webapp" { })
    (createScript "omarchy-launch-browser" {
      inherit (exe) uwsm-app xdg-settings;
      webappBrowser = getExe cfg.browser.webapp;
    })
    (createScript "omarchy-launch-screensaver" {
      inherit (exe)
        hyprctl
        jq
        notify-send
        xdg-terminal-exec
        walker
        ;
      alacrittyConf = path { path = ../../../default/alacritty/screensaver.toml; };
      ghosttyConf = path { path = ../../../default/ghostty/screensaver; };
    })
    (createScript "omarchy-launch-tui" {
      inherit (exe) uwsm-app xdg-terminal-exec;
    })
    (createScript "omarchy-launch-walker" {
      inherit (exe) uwsm-app walker;
    })
    (createScript "omarchy-launch-webapp" {
      inherit (exe) xdg-settings uwsm-app;
      webappBrowser = getExe cfg.browser.webapp;
    })
    (createScript "omarchy-webapp-handler-gmail" {
      inherit (exe) sed;
    })
    (createScript "omarchy-webapp-handler-zoom" {
      inherit (exe) sed;
    })
    (createScript "omarchy-launch-wifi" {
      inherit (exe) impala;
    })
    (createScript "omarchy-system-lock" {
      inherit (exe) hyprctl hyprlock;
    })
    (createScript "omarchy-menu" {
      inherit (exe)
        bash
        hyprpicker
        notify-send
        powerprofilesctl
        uwsm-app
        xdg-terminal-exec
        walker
        ;
    })
    (createScript "omarchy-menu-keybindings" {
      inherit (exe)
        bc
        awk
        hyprctl
        jq
        xkbcli
        walker
        ;
    })
    (createScript "omarchy-notification-dismiss" {
      inherit (exe)
        grep
        sed
        makoctl
        ;
    })
    (createScript "omarchy-pkg-install" {
      inherit (exe)
        awk
        fzf
        jq
        sed
        ;
    })
    (createScript "omarchy-pkg-remove" {
      inherit (exe) fzf jq;
    })
    (createScript "omarchy-powerprofiles-init" { })
    (createScript "omarchy-powerprofiles-list" {
      inherit (exe) awk powerprofilesctl;
    })
    (createScript "omarchy-restart-app" {
      inherit (exe) uwsm-app;
    })
    (createScript "omarchy-restart-hypridle" { })
    (createScript "omarchy-restart-hyprsunset" { })
    (createScript "omarchy-restart-swayosd" { })
    (createScript "omarchy-restart-walker" { })
    omarchy-restart-terminal
    omarchy-restart-waybar
    (createScript "omarchy-setup-dns" {
      inherit (exe) gum notify-send;
    })
    (createScript "omarchy-show-done" {
      inherit (exe) bash gum;
    })
    (createScript "omarchy-show-logo" {
      logo = path { path = ../../../logo.txt; };
    })
    (createScript "omarchy-state" {
      inherit (exe) find;
    })
    (createScript "omarchy-system-reboot" { })
    (createScript "omarchy-system-shutdown" { })
    omarchy-theme-bg-next
    omarchy-theme-bg-set
    omarchy-theme-set-obsidian
    (createScript "omarchy-toggle-enabled" { })
    (createScript "omarchy-toggle-idle" {
      inherit (exe)
        hypridle
        notify-send
        uwsm-app
        ;
    })
    (createScript "omarchy-toggle-nightlight" {
      inherit (exe)
        grep
        hyprctl
        hyprsunset
        notify-send
        ;
    })
    (createScript "omarchy-toggle-screensaver" { })
    (createScript "omarchy-toggle-waybar" {
      inherit (exe) systemctl;
    })
    (createScript "omarchy-tz-select" {
      inherit (exe) sed gum;
      CONFIG_FILE = "redo this implementation";
    })
    (createScript "omarchy-update-available" { })
    (createScript "omarchy-update-restart" {
      inherit (exe) gum sed;
    })
  ];
in
{
  options.omarchy.scripts = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Internal access to omarchy scripts";
  };

  config = lib.mkMerge [
    # Scripts available without hyprland
    {
      omarchy.scripts = {
        inherit omarchy-theme-set-obsidian;
      };
    }
    # Hyprland-dependent scripts
    (mkIf cfg.hyprland.enable {
      omarchy.scripts = {
        inherit
          omarchy-restart-terminal
          omarchy-restart-walker
          omarchy-restart-waybar
          omarchy-theme-bg-next
          ;
      };
      home.packages = allScripts;

    # Restart apps on activation so they pick up theme changes.
    # Import wayland env vars since activation runs without them.
    home.activation.restartThemedApps = lib.hm.dag.entryAfter [ "onFilesChange" "reloadSystemd" ] ''
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      eval "$(${p.systemd}/bin/systemctl --user show-environment 2>/dev/null | ${p.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE)=')" || true
      export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" HYPRLAND_INSTANCE_SIGNATURE="''${HYPRLAND_INSTANCE_SIGNATURE:-}"

      ${omarchy-theme-bg-next}/bin/omarchy-theme-bg-next >/dev/null 2>&1 || true
      # uwsm-app doesn't work in activation context; start swaybg in its own scope
      # so it survives the activation service's cgroup cleanup
      sleep 0.2
      if ! ${p.procps}/bin/pgrep -x .swaybg-wrapped >/dev/null 2>&1; then
        ${p.systemd}/bin/systemd-run --user --scope --unit=swaybg-activation \
          ${p.swaybg}/bin/swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &
      fi

      ${omarchy-restart-terminal}/bin/omarchy-restart-terminal >/dev/null 2>&1 || true
    '';
    })
  ];
}
