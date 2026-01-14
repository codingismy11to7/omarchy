{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;

  themeFile = path { path = ../../../themes/${cfg.theme}/alacritty.toml; };
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
      "alacritty/alacritty.toml".source =
        pkgs.replaceVars (path { path = ../../../config/alacritty/alacritty.toml; })
          {
            inherit themeFile;
            font = cfg.font.name;
          };
    };
  }
]
