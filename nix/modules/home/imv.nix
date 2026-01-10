{ pkgs, ... }:
{
  programs.imv.enable = true;

  xdg.configFile."imv/config".source = pkgs.replaceVars ../../../config/imv/config {
    inherit (pkgs) imagemagick;
  };
}
