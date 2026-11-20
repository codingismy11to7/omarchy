{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;

  cfg = config.omarchy;
  chromium = config.programs.chromium;
in
{
  config = mkIf cfg.enable {
    # NixOS's chromium module writes these policies for chromium, chrome and
    # brave, but not for edge. Edge rejects BrowserThemeColor as an unknown
    # policy; it's themed with an extension instead (see home.nix)
    environment.etc."opt/edge/policies/managed/extra.json" =
      mkIf (chromium.enable && chromium.extraOpts != { })
        {
          text = builtins.toJSON (removeAttrs chromium.extraOpts [ "BrowserThemeColor" ]);
        };
  };
}
