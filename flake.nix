{
  description = "Omarchy on NixOS";

  nixConfig = {
    extra-substituters = [ "https://nix-cache.codingismy11to7.us/omarchy" ];
    extra-trusted-public-keys = [ "omarchy:TRPnFp7RNU+BhR64bXpG61cNE7TlB53BAoc7wEmhzyE=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terminaltexteffects = {
      url = "github:ChrisBuilds/terminaltexteffects";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    elephant = {
      url = "github:abenz1267/elephant/v2.21.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    voxtype = {
      url = "github:peteonrails/voxtype";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    walker = {
      url = "github:abenz1267/walker/v2.16.2";
      inputs = {
        elephant.follows = "elephant";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    hyprland-preview-share-picker = {
      url = "github:codingismy11to7/hyprland-preview-share-picker/nix";
      inputs.flake-utils.follows = "flake-utils";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        systems = import inputs.systems;

        flake = {
          homeManagerModules = {
            default = self.homeManagerModules.omarchy;
            omarchy = importApply ./nix/modules/home-manager.nix { inherit self inputs; };
          };

          lazyvimTheme = {
            default = self.lazyvimTheme.omarchy;
            omarchy = import ./nix/modules/lazyvim-theme.nix;
            # Standalone function for use without omarchy home-manager module
            forTheme =
              theme:
              with builtins;
              readFile (path {
                path = ./themes/${theme}/neovim.lua;
              });
          };

          nixosModules = {
            default = self.nixosModules.omarchy;
            omarchy = importApply ./nix/modules/nixos.nix { inherit self inputs; };
          };

          stylixTheme = import ./nix/modules/stylix-theme.nix;

          nixosConfigurations = import ./nix/installer.nix {
            inherit inputs self;
            systems = import inputs.systems;
          };
        };

        perSystem =
          {
            config,
            self',
            inputs',
            pkgs,
            system,
            ...
          }:
          {
            formatter = pkgs.nixfmt;

            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                nixd
                uv

                (writeShellScriptBin "build-installer" ''
                  nix build .#nixosConfigurations.installer-${system}.config.system.build.isoImage "$@"
                '')

                (writeShellScriptBin "test-installer" ''
                  set -eEo pipefail
                  REPO_ROOT="$(git rev-parse --show-toplevel)"
                  PHASES="$REPO_ROOT/install/packaging/phases"

                  # Load defaults, allow env overrides
                  set -a
                  source "$REPO_ROOT/install/packaging/test-defaults.env"
                  set +a

                  export OMARCHY_TEST_MODE=1
                  export OMARCHY_INSTALL_LOG_FILE="''${OMARCHY_INSTALL_LOG_FILE:-/tmp/omarchy-test-install.log}"
                  export OMARCHY_TEST_FACTER_JSON="''${OMARCHY_TEST_FACTER_JSON:-$REPO_ROOT/install/packaging/test-facter.json}"
                  export OMARCHY_TEST_REPO="''${OMARCHY_TEST_REPO:-$REPO_ROOT}"

                  echo "=== Omarchy Installer Test Mode ==="
                  echo "Hostname: $OMARCHY_HOSTNAME"
                  echo "User: $OMARCHY_USER_NAME"
                  echo "Working in: /tmp/dotfiles"
                  echo ""

                  source "$PHASES/clone-dotfiles.sh"
                  source "$PHASES/configure-secrets.sh"
                  source "$PHASES/install-system.sh"

                  echo ""
                  echo "=== Test completed successfully ==="
                  echo "Dotfiles at: /tmp/dotfiles"
                  echo "Secrets at: /tmp/secrets"
                '')

                (writeShellScriptBin "lint" ''
                  if [[ "$1" == "--fix" ]]; then
                    shift
                    ${lib.getExe statix} fix "$@"
                    ${lib.getExe deadnix} -e "$@"
                  else
                    EXIT_CODE=0
                    ${lib.getExe statix} check "$@" || EXIT_CODE=1
                    ${lib.getExe deadnix} "$@" || EXIT_CODE=1
                    exit $EXIT_CODE
                  fi
                '')
              ];
            };

            checks = {
              test-build =
                (inputs.nixpkgs.lib.nixosSystem {
                  inherit system;
                  specialArgs = { inherit inputs; };
                  modules = [
                    self.nixosModules.default
                    inputs.home-manager.nixosModules.home-manager
                    {
                      nixpkgs.config.allowUnfree = true;
                      fileSystems."/".device = "/dev/null";
                      boot.loader.grub.enable = false;
                      system.stateVersion = "25.11";
                      omarchy = {
                        enable = true;
                        username = "testuser";
                        gaming = {
                          enable = true;
                          steam = true;
                          heroicGameLauncher = true;
                        };
                      };
                      users.users.testuser = {
                        isNormalUser = true;
                        group = "testuser";
                      };
                      users.groups.testuser = { };
                      home-manager = {
                        useUserPackages = true;
                        useGlobalPkgs = true;
                        extraSpecialArgs = { inherit inputs; };
                        users.testuser = {
                          imports = [
                            self.homeManagerModules.default
                          ];

                          home.stateVersion = "25.11";
                          omarchy = {
                            git = {
                              userName = "Test User";
                              userEmail = "test@example.com";
                            };
                            ai.claudeCode.enable = true;
                            ai.codexCli.enable = true;
                            voxtype.enable = true;
                          };
                        };
                      };
                    }
                  ];
                }).config.system.build.toplevel;
            };
          };
      }
    );
}
