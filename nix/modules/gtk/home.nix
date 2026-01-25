{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  inherit (cfg) lightMode theme;
  p = cfg._packages;
  inherit (lib) hasPrefix removeSuffix;

  iconsFile = ../../../themes + "/${theme}/icons.theme";
  iconName =
    let
      name = if pathExists iconsFile then removeSuffix "\n" (readFile iconsFile) else "Yaru-blue";
    in
    if hasPrefix "Yaru-" name then
      name
    else
      throw "Theme '${theme}' has unsupported icon theme '${name}'.";

  settings = {
    colorScheme = if lightMode then "light" else "dark";
    iconTheme = {
      name = iconName;
      package = p.yaru-theme;
    };
  };
in
{
  gtk = {
    enable = true;
    gtk2.enable = false;

    gtk3 = settings;
    gtk4 = settings;
  };
}
