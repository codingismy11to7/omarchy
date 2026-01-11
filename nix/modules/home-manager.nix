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
  inherit (lib)
    splitString
    findFirst
    hasPrefix
    toInt
    last
    ;
  inherit (lib.modules) mkIf;

  cfg = config.omarchy;

  envFile = ../../default/hypr/envs.conf;

  cursorSize =
    let
      lines = splitString "\n" (readFile envFile);
      line = findFirst (l: hasPrefix "env = XCURSOR_SIZE," l) null lines;
    in
    if line != null then
      toInt (last (splitString "," line))
    else
      throw "Failed to extract XCURSOR_SIZE from ${envFile}. The file format may have changed and the parsing logic in nix/modules/home-manager.nix needs to be updated.";
in
{
  imports = [
    inputs.walker.homeManagerModules.default
    ./home/alacritty.nix
    ./home/btop.nix
    ./home/ghostty.nix
    ./home/gtk.nix
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

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = cursorSize;
    };
  };
}
