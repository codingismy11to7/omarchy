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
  inherit (lib.types)
    nullOr
    str
    submodule
    ;
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
  imports = [
    ./bash/core.nix
    ./gaming/core.nix
    ./qt/core.nix
    ./sddm/core.nix
  ];

  options = {
    omarchy = {
      bash = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "Bash shell with omarchy configuration" // {
              default = true;
            };
            package = mkPackageOption pkgs "bash" { };
          };
        };
        default = { };
      };

      enable = mkEnableOption self.description;

      gaming = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "gaming support (Steam, Heroic)";
            heroicGameLauncher = mkEnableOption "Heroic (GOG/Epic/Amazon launcher)";
            steam = mkEnableOption "Steam with Gamescope";
            steamRealtime = mkEnableOption "real-time scheduling for Gamescope";
          };
        };
        default = { };
      };

      hyprland = mkOption {
        type = submodule {
          options = {
            package = mkPackageOption pkgs "hyprland" { };
            portalPackage = mkPackageOption pkgs "xdg-desktop-portal-hyprland" { };
          };
        };
        default = { };
      };

      qtEnableAdwaita = mkEnableOption "Adwaita theme for Qt applications";

      username = mkOption {
        type = str;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      inherit (cfg.hyprland) package portalPackage;
      withUWSM = true;
    };

    # pdf viewer that omarchy sets as default
    programs.evince.enable = true;

    services = {
      # quick previewer for nautilus
      gnome.sushi.enable = true;

      gvfs.enable = true;

      dbus.packages = [ pkgs.nautilus ];
    };

    environment.systemPackages = [ pkgs.nautilus ];
  };
}
