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
  inherit (lib.types) nullOr bool submodule;
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

      hyprland = mkOption {
        type = nullOr (submodule {
          options = {
            package = mkPackageOption pkgs "hyprland" { };
          };
        });
      };
    };
  };

  config = mkIf cfg.enable {
    omarchy.hyprland = mkDefault { };

    programs.hyprland = {
      enable = true;
      package = cfg.hyprland.package;
      withUWSM = true;
    };

    # quick previewer for nautilus
    services.gnome.sushi.enable = true;

    environment.systemPackages = with pkgs; [
      nautilus
    ];
  };
}
