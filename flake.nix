{
  description = "Omarchy on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terminaltexteffects = {
      # url = "github:ChrisBuilds/terminaltexteffects/release-0.14.2";
      url = "github:codingismy11to7/terminaltexteffects/fix_nix_build";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    elephant = {
      url = "github:abenz1267/elephant/2.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    walker = {
      url = "github:abenz1267/walker/2.0.0";
      inputs = {
        elephant.follows = "elephant";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    hyprland-preview-share-picker.url = "github:codingismy11to7/hyprland-preview-share-picker/nix";
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      systems,
      terminaltexteffects,
      walker,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      eachSystem = lib.genAttrs (import systems);
      forAllSystems = f: eachSystem (system: f nixpkgs.legacyPackages.${system});
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      homeManagerModules = {
        default = self.homeManagerModules.omarchy;
        omarchy = import ./nix/modules/home-manager.nix { inherit self inputs; };
      };

      nixosModules = {
        default = self.nixosModules.omarchy;
        omarchy = import ./nix/modules/nixos.nix { inherit self inputs; };
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          shellHook = ''
            echo "*** watch for changes with 'dev-mode' ***"
          '';
          packages = with pkgs; [
            watchexec
            (pkgs.writeShellScriptBin "dev-mode" ''
              watchexec --restart --clear --ignore result nix flake check
            '')
          ];
        };
      });

      checks = eachSystem (system: {
        test-build =
          (lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [
              self.nixosModules.default
              home-manager.nixosModules.home-manager
              {

                fileSystems."/".device = "/dev/null";
                boot.loader.grub.enable = false;
                system.stateVersion = "25.11";
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
                    omarchy.enable = true;
                    omarchy.browser = "brave";
                  };
                };
              }
            ];
          }).config.system.build.toplevel;
      });
    };
}
