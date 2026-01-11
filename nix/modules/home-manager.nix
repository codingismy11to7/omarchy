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
  inherit (lib.modules) mkIf;

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
    ./home/options.nix
    ./home/scripts.nix
    ./home/swayosd.nix
    ./home/walker.nix
    ./home/waybar.nix
  ];

  config = mkIf cfg.enable {
    _module.args.omarchyInputs = inputs;
    _module.args.self = self;

    home.packages = with pkgs; [
      cfg.font.package
      liberation_ttf
    ];

    xdg.configFile."fontconfig/conf.d/50-omarchy.conf".source =
      pkgs.replaceVars ../../config/fontconfig/fonts.conf
        { font = config.omarchy.font.name; };
  };
}
