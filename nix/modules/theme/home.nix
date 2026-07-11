{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
in
{
  xdg.configFile = {
    # Upstream scripts resolve the active theme through these at runtime
    # (omarchy-theme-bg-switcher reads theme.name and lists theme/backgrounds;
    # omarchy-menu-images themes its quickshell picker from quickshell.json).
    "omarchy/current/theme.name".text = cfg.theme;
    "omarchy/current/theme/backgrounds".source = path {
      path = ../../../themes/${cfg.theme}/backgrounds;
    };
    "omarchy/current/theme/quickshell.json".source =
      pkgs.replaceVars
        (path {
          path = ../../../default/themed/quickshell.json.tpl;
        })
        {
          inherit (cfg.palette) accent background foreground;
        };

    "omarchy/current/theme/obsidian.css".source =
      pkgs.replaceVars
        (path {
          path = ../../../default/themed/obsidian.css.tpl;
        })
        {
          inherit (cfg.palette)
            background
            foreground
            selection_background
            color8
            color1
            color2
            color3
            color4
            color5
            accent
            color6
            ;
        };
    "omarchy/current/theme/chromium.theme".source = pkgs.replaceVars (path {
      path = ../../../default/themed/chromium.theme.tpl;
    }) { inherit (cfg.palette) background_rgb; };
  };
}
