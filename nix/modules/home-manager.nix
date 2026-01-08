{
  self,
  inputs,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.trivial) importTOML;
  inherit (lib.meta) getExe;
  inherit (lib.types)
    nullOr
    bool
    enum
    str
    ;
  inherit (lib)
    optional
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
  imports = [
    inputs.walker.homeManagerModules.default
    ./home/walker.nix
    ./home/waybar.nix
  ];

  options = {
    omarchy = {
      enable = mkEnableOption self.description;

      browser = mkOption {
        type = str;
        description = "The chromium-based web browser to use for launching webapps.";
      };

      theme = mkOption {
        type = enum (attrNames (readDir ../../themes));
        default = "gruvbox";
      };

      twelveHourClock = mkOption {
        type = bool;
        default = true;
        example = false;
        description = "Show am/pm in Waybar";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      (import ./home/scripts.nix {
        inherit
          cfg
          inputs
          lib
          pkgs
          ;
      }).allScripts;
  };
}
