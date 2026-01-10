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
    ./home/alacritty.nix
    ./home/btop.nix
    ./home/ghostty.nix
    ./home/hyprland-preview-share-picker.nix
    ./home/hyprlock.nix
    ./home/hyprsunset.nix
    ./home/imv.nix
    ./home/kitty.nix
    ./home/mako.nix
    ./home/swayosd.nix
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

      font = {
        package = mkPackageOption pkgs.nerd-fonts "font" {
          default = "jetbrains-mono";
          example = "fira-code";
          pkgsText = "pkgs.nerd-fonts";
        };
        name = mkOption {
          type = str;
          default = "JetBrainsMono Nerd Font";
          example = "FiraCode Nerd Font";
        };
      };

      terminal = mkOption {
        type = enum [
          "ghostty"
          "kitty"
          "alacritty"
        ];
        default = "ghostty";
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
      with pkgs;
      [
        cfg.font.package
        liberation_ttf
      ]
      ++ (import ./home/scripts.nix {
        inherit
          cfg
          inputs
          lib
          pkgs
          ;
      }).allScripts;

    xdg.configFile."fontconfig/conf.d/50-omarchy.conf".source =
      pkgs.replaceVars ../../config/fontconfig/fonts.conf
        { font = config.omarchy.font.name; };
  };
}
