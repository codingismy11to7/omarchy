{
  config,
  lib,
  pkgs,
  ...
}:
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
      "elephant/calc.toml".source = ../../../config/elephant/calc.toml;
      "elephant/desktopapplications.toml".source = ../../../config/elephant/desktopapplications.toml;
      "elephant/menus/omarchy_themes.lua".source =
        pkgs.replaceVars ../../../default/elephant/omarchy_themes.lua
          { omarchyThemesDir = ../../../themes; };

      "walker/config.toml".source = ../../../config/walker/config.toml;
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/layout.xml".source =
      ../../../default/walker/themes/omarchy-default/layout.xml;

    dataFile."omarchy/default/walker/themes/omarchy-default/style.css".source =
      pkgs.replaceVars ../../../default/walker/themes/omarchy-default/style.css
        { styleImport = ../../../themes/${cfg.theme}/walker.css; };
  };
}
