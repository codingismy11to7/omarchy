{
  config,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;

  inherit (pkgs.stdenv.hostPlatform) isx86;
in
{
  programs.btop = {
    enable = true;
    package = pkgs.btop.override {
      rocmSupport = isx86;
      cudaSupport = isx86;
    };
  };

  xdg.configFile."btop/btop.conf".source = path { path = ../../../config/btop/btop.conf; };
  xdg.configFile."btop/themes/current.theme".source = path {
    path = ../../../themes/${cfg.theme}/btop.theme;
  };
}
