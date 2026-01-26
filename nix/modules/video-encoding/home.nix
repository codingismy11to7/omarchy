{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;

  cfg = config.omarchy;
  videoEncoding = osConfig.omarchy.videoEncoding or null;
in
mkIf (cfg.enable && videoEncoding != null && videoEncoding.enable) {
  home.packages =
    [ pkgs.handbrake ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ pkgs.makemkv ];
}
