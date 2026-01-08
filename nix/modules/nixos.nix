{ self, inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.trivial) importTOML;
  inherit (lib.meta) getExe;
  inherit (lib.types) nullOr bool;
  inherit (lib)
    optionalString
    types
    mapAttrs'
    mapAttrsToList
    nameValuePair
    mkDefault
    literalExpression
    ;

  cfg = config.omarchy;
in
{
  options = {
    omarchy = {
      enable = mkEnableOption self.description;
    };
  };

  config = mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

  };
}
