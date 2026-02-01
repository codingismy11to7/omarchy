{ config, lib, pkgs, ... }:
with builtins;
let
  inherit (lib.modules) mkIf;
  cfg = config.omarchy;

  themeCss = pkgs.replaceVars (path { path = ../../../default/themed/swayosd.css.tpl; }) {
    inherit (config.omarchy.palette) background foreground accent;
  };
in
mkIf (cfg._packages.swayosd != null) {
  services.swayosd = {
    enable = true;
    package = cfg._packages.swayosd;
  };

  xdg.configFile."swayosd/config.toml".source = path { path = ../../../config/swayosd/config.toml; };
  xdg.configFile."swayosd/style.css".source =
    pkgs.replaceVars (path { path = ../../../config/swayosd/style.css; })
      {
        inherit themeCss;
        font = cfg.font.name;
      };
}
