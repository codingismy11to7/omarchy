{
  inputs,
  self,
  systems,
}:
with builtins;
let
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mkForce;
  omarchyPath = path { path = ./..; };
  installScript = path { path = ../install.sh; };
  logoPath = path { path = ../logo.txt; };

  errorsSh = path { path = ../install/helpers/errors.sh; };
  loggingSh = path { path = ../install/helpers/logging.sh; };
  preflightBeginSh = path { path = ../install/preflight/begin.sh; };
  preflightShowEnvSh = path { path = ../install/preflight/show-env.sh; };
  setupKeyboardShRaw = path { path = ../install/setup/keyboard.sh; };
  setupWifiSh = path { path = ../install/setup/wifi.sh; };
  setupAccountSh = path { path = ../install/setup/account.sh; };
  setupDiskSh = path { path = ../install/setup/disk.sh; };
  nixInstallSh = path { path = ../install/packaging/nix-install.sh; };
  postInstallFinishedShRaw = path { path = ../install/post-install/finished.sh; };
in
listToAttrs (
  map (system: {
    name = "installer-${system}";
    value = lib.nixosSystem {
      inherit system;
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (
          { pkgs, ... }:
          let
            inherit (pkgs) replaceVars writeShellScriptBin;
            presentationSh = replaceVars (path { path = ../install/helpers/presentation.sh; }) {
              inherit logoPath;
              awk = getExe pkgs.gawk;
            };
            helpersAll = replaceVars (path { path = ../install/helpers/all.sh; }) {
              inherit presentationSh errorsSh loggingSh;
            };
            preflightAll = replaceVars (path { path = ../install/preflight/all.sh; }) {
              inherit preflightBeginSh preflightShowEnvSh;
            };
            setupKeyboardSh = replaceVars setupKeyboardShRaw {
              awk = getExe pkgs.gawk;
              xkbRules = "${pkgs.xkeyboard-config}/share/X11/xkb/rules/evdev.lst";
            };
            setupAll = replaceVars (path { path = ../install/setup/all.sh; }) {
              inherit setupKeyboardSh setupWifiSh setupAccountSh setupDiskSh;
            };
            postInstallFinishedSh = replaceVars postInstallFinishedShRaw {
              inherit logoPath;
              tte = getExe inputs.terminaltexteffects.packages.${system}.default;
              gum = getExe pkgs.gum;
            };
            postInstallAll = replaceVars (path { path = ../install/post-install/all.sh; }) {
              inherit postInstallFinishedSh;
            };
            omarchyInstall = writeShellScriptBin "omarchy-install" ''
              exec bash ${
                replaceVars installScript {
                  inherit helpersAll preflightAll setupAll postInstallAll nixInstallSh;
                }
              } "$@"
            '';
          in
          {
            environment.systemPackages = with pkgs; [
              git
              gum
              gawk
              gnugrep
              gnused
              kbd
              mdcat
              omarchyInstall
            ];

            # Auto-launch the installer on login
            programs.bash.loginShellInit = ''
              if [ "$(tty)" = "/dev/tty1" ] && [ "$USER" = "nixos" ]; then
                omarchy-install
              fi
            '';

            nix.settings = {
              experimental-features = [ "nix-command" "flakes" ];
              extra-substituters = [
                "https://nix-cache.codingismy11to7.us/omarchy"
                "https://hyprland.cachix.org"
                "https://nix-community.cachix.org"
                "https://numtide.cachix.org"
                "https://walker-git.cachix.org"
              ];
              extra-trusted-public-keys = [
                "omarchy:TRPnFp7RNU+BhR64bXpG61cNE7TlB53BAoc7wEmhzyE="
                "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
                "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
              ];
            };

            services.getty.helpLine = mkForce "Omarchy Installer";
          }
        )
      ];
    };
  }) systems
)
