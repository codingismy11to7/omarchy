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
    # the walker home-manager module enables elephant, so
    # configure it here
    configFile.elephant = {
      source = ../../../config/elephant;
      recursive = true;
    };

    dataFile."omarchy/default/walker/themes/omarchy-default/layout.xml".source =
      ../../../default/walker/themes/omarchy-default/layout.xml;

    dataFile."omarchy/default/walker/themes/omarchy-default/style.css".source =
      pkgs.replaceVars ../../../default/walker/themes/omarchy-default/style.css
        { styleImport = ../../../themes/${cfg.theme}/walker.css; };

    configFile = {
      "walker/config.toml".source = ../../../config/walker/config.toml;
    };
  };
}
