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
lib.mkIf cfg.enable {
  programs.walker = {
    enable = true;
    runAsService = true;
    config = { };
  };

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
      }) { omarchyThemesDir = path { path = ../../../themes; }; };

      "walker/config.toml".source = path { path = ../../../config/walker/config.toml; };
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/layout.xml".source = path {
      path = ../../../default/walker/themes/omarchy-default/layout.xml;
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/style.css".source = pkgs.replaceVars (path {
      path = ../../../default/walker/themes/omarchy-default/style.css;
    }) { styleImport = path { path = ../../../themes/${cfg.theme}/walker.css; }; };
  };
}
