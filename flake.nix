{
  description = "Omarchy on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
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
      nixpkgs,
      systems,
      terminaltexteffects,
      walker,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      forAllSystems = f: lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      homeManagerModules = {
        default = self.homeManagerModules.omarchy;
        omarchy = import ./nix/modules/home-manager.nix { inherit self inputs; };
      };
    };
}
