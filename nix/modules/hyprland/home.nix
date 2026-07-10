{
  config,
  lib,
  omarchyInputs,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;
  inherit (cfg) qtEnableAdwaita;
  hyprCfg = cfg.hyprland;
  p = cfg._packages;

  inherit (lib) getExe getExe';
  inherit (pkgs.stdenv.hostPlatform) system;

  hyprland-preview-share-picker =
    omarchyInputs.hyprland-preview-share-picker.packages.${system}.default;

  voxtype =
    let
      voxtypePkgs = omarchyInputs.voxtype.packages.${system};
      unwrapped =
        if !cfg.voxtype.enable then
          null
        else if cfg.voxtype.variant == "vulkan" then
          voxtypePkgs.voxtype-vulkan-unwrapped
        else if cfg.voxtype.variant == "rocm" then
          voxtypePkgs.voxtype-rocm-unwrapped
        else
          voxtypePkgs.voxtype-unwrapped;
    in
    if unwrapped == null then
      null
    else
      pkgs.symlinkJoin {
        name = "${unwrapped.pname or "voxtype"}" + "-wrapped-${unwrapped.version}";
        paths = [ unwrapped ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/voxtype \
            --prefix PATH : ${
              lib.makeBinPath [
                p.wl-clipboard
                p.libnotify
                cfg.voxtype.ydotool
              ]
            }
        '';
        inherit (unwrapped) meta;
      };

  voxtypeBindings =
    if cfg.voxtype.enable then
      ''
        o.bind("SUPER + CTRL + X", "Start dictation", "${getExe voxtype} record start")
        o.bind("SUPER + CTRL + X", "Stop dictation", "${getExe voxtype} record stop", { release = true })''
    else
      "";

  envsExtra =
    let
      envsLines = concatStringsSep "\n" (
        attrValues (mapAttrs (k: v: ''hl.env("${k}", "${v}")'') hyprCfg.envs)
      );
    in
    envsLines
    + (if envsLines != "" && hyprCfg.envsExtra != "" then "\n" else "")
    + hyprCfg.envsExtra;

  # Option-substituted overlays for the shared OMARCHY_PATH defaults tree.
  # Everything else in the tree ships as-is from the repo.
  defaultOverlays = {
    "default/hypr/helpers.lua" = pkgs.replaceVars (path { path = ../../../default/hypr/helpers.lua; }) {
      uwsm-app = getExe' p.uwsm "uwsm-app";
      notify-send = getExe' p.libnotify "notify-send";
    };
    "default/hypr/autostart.lua" =
      pkgs.replaceVars (path { path = ../../../default/hypr/autostart.lua; })
        {
          hypridle = getExe p.hypridle;
          swaybg = getExe p.swaybg;
        };
    "default/hypr/envs.lua" = pkgs.replaceVars (path { path = ../../../default/hypr/envs.lua; }) {
      qtTheme =
        if qtEnableAdwaita then
          (if config.omarchy.lightMode then "adwaita" else "adwaita-dark")
        else
          "kvantum";
      xcompose = path { path = ../../../default/xcompose; };
      inherit envsExtra;
    };
    "default/hypr/input.lua" = pkgs.replaceVars (path { path = ../../../default/hypr/input.lua; }) {
      inherit (cfg.keyboard) layout variant options;
    };
    "default/hypr/bindings/media.lua" =
      pkgs.replaceVars (path { path = ../../../default/hypr/bindings/media.lua; })
        {
          volUpCmd = if cfg.media.sensitiveVolume then "+1" else "raise";
          volDownCmd = if cfg.media.sensitiveVolume then "-1" else "lower";
          volUpDesc = if cfg.media.sensitiveVolume then "Volume up precise" else "Volume up";
          volDownDesc = if cfg.media.sensitiveVolume then "Volume down precise" else "Volume down";
          volUpAltCmd = if cfg.media.sensitiveVolume then "raise" else "+1";
          volDownAltCmd = if cfg.media.sensitiveVolume then "lower" else "-1";
          volUpAltDesc = if cfg.media.sensitiveVolume then "Volume up" else "Volume up precise";
          volDownAltDesc = if cfg.media.sensitiveVolume then "Volume down" else "Volume down precise";
        };
    "default/hypr/bindings/utilities.lua" =
      pkgs.replaceVars (path { path = ../../../default/hypr/bindings/utilities.lua; })
        {
          gnome-calculator = getExe p.gnome-calculator;
          makoctl = getExe' p.mako "makoctl";
          hyprctl = getExe' hyprCfg.package "hyprctl";
          inherit voxtypeBindings;
        };
  };

  # The tree OMARCHY_PATH points at: upstream repo dirs with the option-substituted
  # lua defaults overlaid. bin/ is deliberately excluded — scripts are installed
  # (substituted) via scripts/home.nix, and raw @marker@ bodies must never be on PATH.
  omarchyPath = pkgs.runCommand "omarchy-path" { } (
    ''
      mkdir -p $out
      cp -r ${path { path = ../../../default; }} $out/default
      cp -r ${path { path = ../../../themes; }} $out/themes
      cp -r ${path { path = ../../../config; }} $out/config
      cp -r ${path { path = ../../../install; }} $out/install
      cp ${path { path = ../../../logo.txt; }} $out/logo.txt
      chmod -R u+w $out
    ''
    + concatStringsSep "\n" (attrValues (mapAttrs (rel: file: "cp ${file} $out/${rel}") defaultOverlays))
  );

  # User-editable config values. These options take Hyprland Lua snippets now
  # (hyprlang is deprecated as of Hyprland 0.55 and all omarchy configs are lua).
  monitorConfig = if hyprCfg.monitorConfig != null then hyprCfg.monitorConfig else "";
  bindingsExtra =
    let
      bindingsLines = concatStringsSep "\n" hyprCfg.bindings;
      extra = if hyprCfg.bindingsExtra != null then hyprCfg.bindingsExtra else "";
    in
    bindingsLines + (if bindingsLines != "" && extra != "" then "\n" else "") + extra;

  gapsSize =
    if !hyprCfg.widerWindowGaps then
      ""
    else
      "hl.config({ general = { gaps_in = 10, gaps_out = 20 } })";
  rounding = "hl.config({ decoration = { rounding = ${if hyprCfg.roundWindowCorners then "8" else "0"} } })";

  screensaver = {
    activationSeconds = toString cfg.screensaver.activationSeconds;
    lockSeconds = toString cfg.screensaver.lockSeconds;
  };
in
mkIf cfg.hyprland.enable {
  services.polkit-gnome.enable = true;

  home.packages = [ p.gnome-calculator ];

  # Scripts and the lua config chain resolve the omarchy tree through this.
  # sessionVariables covers login shells; systemd.user covers the uwsm-managed
  # Hyprland session (the lua loader reads it at config parse time). The entry
  # hyprland.lua also gets the store path substituted as its fallback.
  home.sessionVariables.OMARCHY_PATH = "${omarchyPath}";
  systemd.user.sessionVariables.OMARCHY_PATH = "${omarchyPath}";

  xdg.configFile = {
    "hypr/hyprland.lua".source =
      pkgs.replaceVars (path { path = ../../../config/hypr/hyprland.lua; })
        {
          inherit omarchyPath;
        };
    "hypr/.luarc.json".source = path { path = ../../../config/hypr/.luarc.json; };
    "hypr/autostart.lua".source = path { path = ../../../config/hypr/autostart.lua; };
    "hypr/input.lua".source = path { path = ../../../config/hypr/input.lua; };
    "hypr/monitors.lua".source =
      pkgs.replaceVars (path { path = ../../../config/hypr/monitors.lua; })
        {
          inherit monitorConfig;
        };
    "hypr/bindings.lua".source =
      pkgs.replaceVars (path { path = ../../../config/hypr/bindings.lua; })
        {
          inherit (cfg) passwordManager;
          inherit bindingsExtra;
        };
    "hypr/looknfeel.lua".source =
      pkgs.replaceVars (path { path = ../../../config/hypr/looknfeel.lua; })
        {
          inherit (hyprCfg) dwindleExtra;
          inherit gapsSize rounding;
        };

    # Theme's Hyprland overrides, required by default/hypr/omarchy.lua as
    # omarchy.current.theme.hyprland.
    "omarchy/current/theme/hyprland.lua".source =
      pkgs.replaceVars (path { path = ../../../default/themed/hyprland.lua.tpl; })
        {
          inherit (config.omarchy.palette) accent_strip;
        };

    "hypr/hypridle.conf".source =
      pkgs.replaceVars (path { path = ../../../config/hypr/hypridle.conf; })
        {
          inherit (screensaver) activationSeconds lockSeconds;
        };

    "hypr/xdph.conf".source = pkgs.replaceVars (path { path = ../../../config/hypr/xdph.conf; }) {
      hyprland-preview-share-picker = getExe' hyprland-preview-share-picker "hyprland-preview-share-picker";
    };
  };
}
