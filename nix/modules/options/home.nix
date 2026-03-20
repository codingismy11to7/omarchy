{
  config,
  lib,
  pkgs,
  self,
  ...
}:
with builtins;
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types)
    attrsOf
    bool
    enum
    float
    int
    lines
    listOf
    nullOr
    oneOf
    str
    submodule
    ;
  inherit (lib)
    concatMapAttrs
    hasPrefix
    importTOML
    literalExpression
    removePrefix
    stringToCharacters
    toUpper
    types
    ;

in
{
  options = {
    omarchy = {
      enable = mkEnableOption self.description;

      packages = mkOption {
        type = attrsOf (nullOr types.package);
        default = { };
        description = "Package overrides for omarchy tools. Merged with internal defaults. Set to null to disable.";
        example = literalExpression ''
          {
            jq = pkgs.jaq;  # Use jaq instead of jq
            brave = pkgs.ungoogled-chromium;  # Use different browser
            mpv = null;  # Disable mpv
          }
        '';
      };

      # Internal option that merges user overrides with defaults
      _packages = mkOption {
        type = attrsOf (nullOr types.package);
        internal = true;
        readOnly = true;
        default =
          let
            defaults = {
              inherit (pkgs)
                # Core CLI tools
                gawk
                bc
                git
                gnugrep
                gnused
                jq
                jaq
                findutils
                brotli
                bash

                # Hyprland ecosystem
                hypridle
                hyprlock
                hyprpicker
                hyprsunset
                swaybg
                swayosd

                # Screenshot/recording
                grim
                slurp
                satty

                # Notifications/UI
                libnotify
                mako
                gum
                waybar

                # System tools
                openssh
                procps
                systemd
                pulseaudio
                wireplumber
                power-profiles-daemon

                # Network/bluetooth
                bluetui
                impala
                localsend

                # Terminal/apps
                alacritty
                eza
                fastfetch
                fzf
                ghostty
                imv
                kitty
                pamixer
                starship
                wiremix
                zoxide

                # Wayland
                wl-clipboard
                uwsm
                xdg-terminal-exec
                xdg-utils

                # Browsers
                brave
                chromium
                google-chrome

                # Theming
                yaru-theme
                adwaita-icon-theme
                imagemagick

                # Misc
                ffmpeg
                fontconfig
                gnome-keyring
                v4l-utils
                libxkbcommon
                brightnessctl
                gnome-calculator
                nautilus

                # Apps
                mpv
                obsidian
                ;
            }
            // lib.optionalAttrs isx86_64 {
              # x86_64-only packages
              inherit (pkgs) gpu-screen-recorder heroic;
            };
          in
          defaults // config.omarchy.packages;
      };

      qtEnableAdwaita = mkEnableOption "Adwaita theme for Qt applications";

      browser = mkOption {
        type = submodule {
          options = {
            webapp = mkPackageOption pkgs "brave" {
              default = "brave";
              example = "microsoft-edge";
              extraDescription = "The chromium-based web browser to use for launching webapps. It will also be used as a fallback if no default browser can be found.";
            };
            copyUrlExtension = mkOption {
              type = types.package;
              readOnly = true;
              description = "The copy-url browser extension package";
            };
            wrapWithExtension = mkOption {
              type = types.functionTo types.package;
              readOnly = true;
              description = "Function to wrap a browser package with omarchy extensions";
            };
            brave = mkOption {
              type = types.package;
              readOnly = true;
              description = "Brave browser wrapped with omarchy extensions";
            };
            chromium = mkOption {
              type = types.package;
              readOnly = true;
              description = "Chromium browser wrapped with omarchy extensions";
            };
            google-chrome = mkOption {
              type = types.package;
              readOnly = true;
              description = "Google Chrome browser wrapped with omarchy extensions";
            };
          };
        };
        default = { };
      };

      firstRunMode = mkOption {
        type = bool;
        default = true;
        description = "Show the introductory notifications.";
      };

      font = mkOption {
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
        default = { };
      };

      git = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "Git version control with omarchy defaults" // {
              default = true;
            };
            userName = mkOption {
              type = str;
              description = "Git user.name for commits";
            };
            userEmail = mkOption {
              type = str;
              description = "Git user.email for commits";
            };
          };
        };
        default = { };
      };

      hyprland = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "Hyprland window manager" // {
              default = true;
            };

            package = mkPackageOption pkgs "hyprland" { };

            monitorConfig = mkOption {
              type = lines;
              default = "";
              example = ''
                env = GDK_SCALE,1
                monitor=,preferred,auto,1
              '';
            };

            widerWindowGaps = mkEnableOption "Enable wider gaps than default.";

            roundWindowCorners = mkEnableOption "Enable rounded window corners";

            dwindleExtra = mkOption {
              type = lines;
              default = "";
              description = "Extra options for dwindle layout, such as setting an aspect ratio for single-window workspaces";
              example = ''
                single_window_aspect_ratio = 16 9
              '';
            };

            bindings = mkOption {
              type = listOf str;
              default = [ ];
              description = "Keybindings to add to the Hyprland configuration.";
              example = [ "bindd = CTRL, F11, Melt Faces, exec, repeat_key_toggle" ];
            };

            bindingsExtra = mkOption {
              type = lines;
              default = "";
              description = "Extra keybindings to add to the Hyprland configuration (raw lines).";
              example = ''
                bindd = CTRL, F11, Melt Faces, exec, repeat_key_toggle
              '';
            };

            envs = mkOption {
              type = attrsOf str;
              default = { };
              description = "Environment variables to add to the Hyprland configuration.";
              example = {
                YDOTOOL_SOCKET = "/run/ydotool/socket";
              };
            };

            envsExtra = mkOption {
              type = lines;
              default = "";
              description = "Extra environment variables to add to the Hyprland configuration (raw lines).";
              example = ''
                env = YDOTOOL_SOCKET,/run/ydotool/socket
              '';
            };
          };
        };
        default = { };
      };

      keyboard = mkOption {
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
        default = { };
      };

      media = mkOption {
        type = submodule {
          options = {
            sensitiveVolume = mkOption {
              type = bool;
              default = false;
              description = "When true, swap the Alt modifier for volume adjustments: 1% by default, 5% with Alt.";
            };
          };
        };
        default = { };
      };

      passwordManager = mkOption {
        type = str;
        default = "1password";
        example = "bitwarden";
        description = "The password manager to use.";
      };

      screensaver = mkOption {
        type = submodule {
          options = {
            text = mkOption {
              type = nullOr lines;
              default = null;
              description = "Custom text to display in the screensaver. If null, uses the Omarchy logo.";
            };
            activationSeconds = mkOption {
              type = int;
              default = 150;
              example = 600;
              description = "Seconds of inactivity before activating the screensaver.";
            };
            lockSeconds = mkOption {
              type = int;
              default = 152; # 2 seconds after screensaver activation
              example = 900;
              description = "Seconds of inactivity before locking the screen.";
            };
          };
        };
        default = { };
      };

      terminal = mkOption {
        type = nullOr (enum [
          "ghostty"
          "kitty"
          "alacritty"
        ]);
        default = "ghostty";
        description = "Terminal emulator to use. Set to null for headless systems.";
      };

      theme = mkOption {
        type = enum (attrNames (readDir ../../../themes));
        default = "tokyo-night";
      };

      themeSetCommand = mkOption {
        type = str;
        default = "omarchy-theme-set";
        description = "Command to run when a theme is selected from the menu. Receives the theme name as an argument.";
      };

      lightMode = mkOption {
        type = bool;
        internal = true;
        default = pathExists (../../../themes + "/${config.omarchy.theme}/light.mode");
      };

      palette = mkOption {
        type = types.attrs;
        description = "Palette of the selected theme";
        default =
          let
            raw = importTOML (../../../themes + "/${config.omarchy.theme}/colors.toml");
            # TODO: the robot wrote this, surely it exists already?
            hexToDec =
              v:
              let
                hexToInt =
                  x:
                  let
                    c = toUpper x;
                    map = {
                      "0" = 0;
                      "1" = 1;
                      "2" = 2;
                      "3" = 3;
                      "4" = 4;
                      "5" = 5;
                      "6" = 6;
                      "7" = 7;
                      "8" = 8;
                      "9" = 9;
                      "A" = 10;
                      "B" = 11;
                      "C" = 12;
                      "D" = 13;
                      "E" = 14;
                      "F" = 15;
                    };
                  in
                  map.${c};
                chars = stringToCharacters v;
                len = length chars;
              in
              if len == 1 then
                hexToInt (head chars)
              else if len == 2 then
                (hexToInt (head chars)) * 16 + (hexToInt (elemAt chars 1))
              else
                throw "hexToDec only supports 1 or 2 chars";

            hexToRgb =
              hex:
              "${toString (hexToDec (substring 0 2 hex))},${toString (hexToDec (substring 2 2 hex))},${
                toString (hexToDec (substring 4 2 hex))
              }";
            strip = hex: removePrefix "#" hex;
          in
          concatMapAttrs (
            name: value:
            if hasPrefix "#" value then
              {
                "${name}" = value;
                "${name}_strip" = strip value;
                "${name}_rgb" = hexToRgb (strip value);
              }
            else
              { "${name}" = value; }
          ) raw;
        readOnly = true;
      };

      twelveHourClock = mkOption {
        type = bool;
        default = true;
        description = "Show am/pm in Waybar";
      };

      bash = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "Bash shell with omarchy configuration" // {
              default = true;
            };
            eza = mkEnableOption "Eza modern ls replacement" // {
              default = true;
            };
            fastfetch = mkOption {
              type = submodule {
                options = {
                  enable = mkEnableOption "Fastfetch system info display";
                  logo = mkOption {
                    type = nullOr types.path;
                    default = null;
                    description = "Path to logo image for fastfetch display.";
                  };
                };
              };
              default = { };
            };
            fzf = mkEnableOption "Fzf fuzzy finder" // {
              default = true;
            };
            sshKeyPrompt = mkEnableOption "Prompt to add SSH key to agent if empty";
            starship = mkEnableOption "Starship prompt" // {
              default = true;
            };
            zoxide = mkEnableOption "Zoxide directory jumper" // {
              default = true;
            };
          };
        };
        default = { };
      };

      obsidian = {
        enable = mkEnableOption "Obsidian with omarchy theming" // {
          default = true;
        };
      };

      voxtype = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "Voxtype push-to-talk voice-to-text";
            variant = mkOption {
              type = enum [
                "default"
                "vulkan"
                "rocm"
              ];
              default = "default";
              description = ''
                Which voxtype build variant to use.
                - default: CPU-only inference
                - vulkan: GPU via Vulkan (cross-vendor)
                - rocm: GPU via ROCm (AMD-only, faster
                  for ML workloads on AMD cards)
              '';
            };
            model = mkOption {
              type = enum [
                "tiny"
                "tiny.en"
                "base"
                "base.en"
                "small"
                "small.en"
                "medium"
                "medium.en"
                "large-v3"
                "large-v3-turbo"
              ];
              default = "base.en";
              description = ''
                Whisper model for transcription. The .en
                variants are English-only but faster.
                large-v3-turbo is recommended for GPU.
              '';
            };
            ydotool = mkPackageOption pkgs "ydotool" { };
            audioFeedback = mkOption {
              type = nullOr (submodule {
                options = {
                  theme = mkOption {
                    type = str;
                    default = "default";
                    example = "subtle";
                    description = ''
                      Sound theme: "default", "subtle",
                      "mechanical", or path to custom theme
                      directory.
                    '';
                  };
                  volume = mkOption {
                    type = float;
                    default = 0.7;
                    description = "Volume level (0.0 to 1.0).";
                  };
                };
              });
              default = null;
              description = "Audio feedback sounds config.";
            };
          };
        };
        default = { };
      };

      ai = mkOption {
        type = submodule {
          options = {
            claudeCode = mkOption {
              type = submodule {
                options = {
                  enable = mkEnableOption "Claude Code AI coding assistant";
                };
              };
              default = { };
            };
          };
        };
        default = { };
      };
    };
  };

}
