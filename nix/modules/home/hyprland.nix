{
  config,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;
  hyprCfg = cfg.hyprland;

  inherit (pkgs.stdenv.hostPlatform) system;

  hyprland-preview-share-picker = inputs.hyprland-preview-share-picker.packages.${system}.default;

  defaults = rec {
    appsDotConf = pkgs.replaceVars ../../../default/hypr/apps.conf {
      appsPath = ../../../default/hypr/apps;
    };
    autostartDotConf = pkgs.replaceVars ../../../default/hypr/autostart.conf {
      inherit (pkgs)
        hypridle
        swaybg
        uwsm
        waybar
        ;
    };
    bindings = {
      mediaDotConf = pkgs.replaceVars ../../../default/hypr/bindings/media.conf {
        inherit (pkgs) hyprland jq swayosd;
      };
      clipboardDotConf = ../../../default/hypr/bindings/clipboard.conf;
      tilingV2DotConf = ../../../default/hypr/bindings/tiling-v2.conf;
      utilitiesDotConf = pkgs.replaceVars ../../../default/hypr/bindings/utilities.conf {
        inherit (pkgs)
          gnome-calculator
          hyprland
          hyprpicker
          libnotify
          mako
          ;
      };
    };
    envsDotConf = pkgs.replaceVars ../../../default/hypr/envs.conf {
      xcompose = ../../../default/xcompose;
    };
    inputDotConf = pkgs.replaceVars ../../../default/hypr/input.conf {
      inherit (cfg.keyboard) layout variant options;
    };
    looknfeelDotConf = ../../../default/hypr/looknfeel.conf;
    windowsDotConf = pkgs.replaceVars ../../../default/hypr/windows.conf { inherit appsDotConf; };
  };

  configs = {
    inputDotConf = ../../../config/hypr/input.conf;
    bindingsDotConf = pkgs.replaceVars ../../../config/hypr/bindings.conf {
      inherit (pkgs) nautilus uwsm xdg-terminal-exec;
    };
    looknfeelDotConf = pkgs.replaceVars ../../../config/hypr/looknfeel.conf {
      inherit (hyprCfg) dwindleExtra;
      rounding = "rounding = ${if hyprCfg.roundWindowCorners then "8" else "0"}";
    };
    monitorsDotConf = pkgs.replaceVars ../../../config/hypr/monitors.conf {
      inherit (hyprCfg) monitorConfig;
    };
    autostartDotConf = ../../../config/hypr/autostart.conf;
  };
in
{
  home.packages = [
    pkgs.polkit_gnome
  ];

  xdg.configFile = {
    "hypr/hyprland.conf".source = pkgs.replaceVars ../../../config/hypr/hyprland.conf {
      defaultAutostartDotConf = defaults.autostartDotConf;
      defaultBindingsMediaDotConf = defaults.bindings.mediaDotConf;
      defaultBindingsClipboardDotConf = defaults.bindings.clipboardDotConf;
      defaultBindingsTilingV2DotConf = defaults.bindings.tilingV2DotConf;
      defaultBindingsUtilitiesDotConf = defaults.bindings.utilitiesDotConf;
      defaultEnvsDotConf = defaults.envsDotConf;
      defaultLooknfeelDotConf = defaults.looknfeelDotConf;
      defaultInputDotConf = defaults.inputDotConf;
      defaultWindowsDotConf = defaults.windowsDotConf;
      themeFile = ../../../themes/${cfg.theme}/hyprland.conf;

      configMonitorsDotConf = configs.monitorsDotConf;
      configInputDotConf = configs.inputDotConf;
      configBindingsDotConf = configs.bindingsDotConf;
      configLooknfeelDotConf = configs.looknfeelDotConf;
      configAutostartDotConf = configs.autostartDotConf;
    };

    "hypr/hypridle.conf".source = pkgs.replaceVars ../../../config/hypr/hypridle.conf {
      inherit (pkgs) brightnessctl hyprland;
    };

    "hypr/xdph.conf".source = pkgs.replaceVars ../../../config/hypr/xdph.conf {
      inherit hyprland-preview-share-picker;
    };
  };
}
