{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with builtins;
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
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

in
{
  options = {
    omarchy = {
      enable = mkEnableOption self.description;

      browser = mkOption {
        type = str;
        description = "The chromium-based web browser to use for launching webapps.";
      };

      font = mkOption {
        type = nullOr (submodule {
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
        });
      };

      hyprland = mkOption {
        type = nullOr (submodule {
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
        });
      };

      keyboard = mkOption {
        type = nullOr (submodule {
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
        });
      };

      screensaver = mkOption {
        type = nullOr (submodule {
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
        });
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
        type = enum (attrNames (readDir ../../../themes));
        default = "gruvbox";
      };

      twelveHourClock = mkOption {
        type = bool;
        default = true;
        description = "Show am/pm in Waybar";
      };
    };
  };

  config = mkIf config.omarchy.enable {
    omarchy = {
      font = mkDefault { };
      hyprland = mkDefault { };
      keyboard = mkDefault { };
      screensaver = mkDefault { };
    };
  };
}
