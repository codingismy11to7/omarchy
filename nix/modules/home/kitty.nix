{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;

  themeFile = path { path = ../../../themes/${cfg.theme}/kitty.conf; };
in
lib.mkIf (cfg.terminal == "kitty") {
  home.packages = [ pkgs.kitty ];

  xdg.configFile = {
    "kitty/config".source = pkgs.replaceVars (path { path = ../../../config/kitty/kitty.conf; }) {
      inherit themeFile;
      font = cfg.font.name;
    };
    "xdg-terminals.list".text = ''
      kitty.desktop
    '';
  };

}
