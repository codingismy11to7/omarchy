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
    float
    int
    lines
    oneOf
    str
    submodule
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
    ./home/hyprland.nix
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

      font = mkOption {
        default = { };
        type = submodule {
          options = {
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
        };
      };

      hyprland = mkOption {
        default = { };
        type = submodule {
          options = {
            monitorConfig = mkOption {
              type = nullOr lines;
              default = null;
              example = ''
                env = GDK_SCALE,1
                monitor=,preferred,auto,1
              '';
            };

            roundWindowCorners = mkEnableOption "Enable rounded window corners";

            dwindleExtra = mkOption {
              type = nullOr lines;
              default = null;
              example = ''
                single_window_aspect_ratio = 16 9
              '';
            };
          };
        };
      };

      keyboard = mkOption {
        default = { };
        type = submodule {
          options = {
            layout = mkOption {
              type = str;
              default = "us";
            };
            variant = mkOption {
              type = nullOr str;
              default = null;
              example = "dvorak";
            };
            options = mkOption {
              type = nullOr str;
              default = "compose:caps";
              example = "compose:ralt";
            };
          };
        };
      };

      screensaver = mkOption {
        default = { };
        type = submodule {
          options = {
            activationMinutes = mkOption {
              type = oneOf [
                float
                int
              ];
              default = 2.5;
              example = 10;
              description = "Minutes of inactivity before activating the screensaver.";
            };
            lockMinutes = mkOption {
              type = oneOf [
                float
                int
              ];
              default = 5;
              example = 15;
              description = "Minutes of inactivity before locking the screen.";
            };
            screenOffDelaySeconds = mkOption {
              type = int;
              default = 30;
              example = 60;
              description = "How long to wait after locking before turning off screen.";
            };
          };
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
        description = "Show am/pm in Waybar";
      };
    };
  };

  config = mkIf cfg.enable {
    _module.args.omarchyInputs = inputs;

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
