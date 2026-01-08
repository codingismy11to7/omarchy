{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;

  themeFile = ../../../themes/${cfg.theme}/kitty.conf;
in
lib.mkIf (cfg.terminal == "kitty") {
  home.packages = [ pkgs.kitty ];

  xdg.configFile = {
    "kitty/config".source = pkgs.replaceVars ../../../config/kitty/kitty.conf {
      inherit themeFile;
      font = cfg.font.name;
    };
    "xdg-terminals.list".text = ''
      kitty.desktop
    '';
  };

}
