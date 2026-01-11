{ pkgs, ... }:
let
  settings = {
    colorScheme = "dark";
    cursorTheme = {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
    };
    iconTheme = {
      name = "Yaru-blue";
      package = pkgs.yaru-theme;
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
