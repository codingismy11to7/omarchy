{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;

  themeFile = ../../../themes/${cfg.theme}/alacritty.toml;
in
lib.mkMerge [
  (lib.mkIf (cfg.terminal == "alacritty") {
    xdg.configFile."xdg-terminals.list".text = ''
      Alacritty.desktop
    '';
  })
  {
    # we're always installing alacritty as an emergency fallback
    home.packages = [ pkgs.alacritty ];

    xdg.configFile = {
      "alacritty/alacritty.toml".source = pkgs.replaceVars ../../../config/alacritty/alacritty.toml {
        inherit themeFile;
      };
    };
  }
]
