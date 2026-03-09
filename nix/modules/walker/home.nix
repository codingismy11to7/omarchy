{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
in
lib.mkIf cfg.hyprland.enable {
  programs.walker = {
    enable = true;
    runAsService = true;
    config = { };
  };

  # Elephant is the data provider for walker's application list.
  # Restart it on activation so it picks up added/removed desktop files.
  home.activation.restartWalker = lib.hm.dag.entryAfter [ "onFilesChange" "reloadSystemd" ] ''
    run ${cfg.scripts.omarchy-restart-walker}/bin/omarchy-restart-walker
  '';

  xdg = {
    configFile = {
      # the walker home-manager module enables elephant, so
      # configure it here
      "elephant/calc.toml".source = path { path = ../../../config/elephant/calc.toml; };
      "elephant/desktopapplications.toml".source = path {
        path = ../../../config/elephant/desktopapplications.toml;
      };
      "elephant/menus/omarchy_themes.lua".source = pkgs.replaceVars (path {
        path = ../../../default/elephant/omarchy_themes.lua;
      }) {
        omarchyThemesDir = path { path = ../../../themes; };
        inherit (cfg) themeSetCommand;
      };
      "elephant/menus/omarchy_background_selector.lua".source = pkgs.replaceVars (path {
        path = ../../../default/elephant/omarchy_background_selector.lua;
      }) {
        inherit (cfg) theme;
        backgroundsDir = path { path = ../../../themes/${cfg.theme}/backgrounds; };
      };
      "elephant/symbols.toml".source = pkgs.replaceVars (path {
        path = ../../../config/elephant/symbols.toml;
      }) {
        wl-copy = "${cfg._packages.wl-clipboard}/bin/wl-copy";
        hyprctl = lib.getExe' cfg.hyprland.package "hyprctl";
      };

      "walker/config.toml".source = path { path = ../../../config/walker/config.toml; };
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/layout.xml".source = path {
      path = ../../../default/walker/themes/omarchy-default/layout.xml;
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/style.css".source =
      pkgs.replaceVars (path { path = ../../../default/walker/themes/omarchy-default/style.css; })
        {
          styleImport = pkgs.replaceVars (path { path = ../../../default/themed/walker.css.tpl; }) {
            inherit (config.omarchy.palette) accent foreground background;
          };
        };
  };

}
