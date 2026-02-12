{
  self,
  inputs,
}:
{
  config,
  lib,
  osConfig ? { },
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
  inherit (lib.modules) mkDefault mkIf mkMerge;

  cfg = config.omarchy;

  envFile = path { path = ../../default/hypr/envs.conf; };

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
    ./ai/home.nix
    ./alacritty/home.nix
    ./bash/home.nix
    ./browser/home.nix
    ./btop/home.nix
    ./fastfetch/home.nix
    ./gaming/home.nix
    ./ghostty/home.nix
    ./git/home.nix
    ./gnome-keyring/home.nix
    ./gtk/home.nix
    ./hyprland/home.nix
    ./hyprland-preview-share-picker/home.nix
    ./hyprlock/home.nix
    ./hyprsunset/home.nix
    ./imv/home.nix
    ./kitty/home.nix
    ./mako/home.nix
    ./mpv/home.nix
    ./obsidian/home.nix
    ./options/home.nix
    ./scripts/home.nix
    ./swayosd/home.nix
    ./theme/home.nix
    ./voxtype/home.nix
    ./walker/home.nix
    ./waybar/home.nix
    ./webapps/home.nix
    ./xdg/home.nix
  ];

  config = mkMerge [
    {
      _module.args.omarchyInputs = inputs;
      _module.args.self = self;
      omarchy.bash.enable = mkDefault (osConfig.omarchy.bash.enable or true);
    }
    (mkIf cfg.hyprland.enable {
      omarchy.qtEnableAdwaita = mkDefault (osConfig.omarchy.qtEnableAdwaita or false);

      home.packages = [
        cfg.font.package
        pkgs.liberation_ttf
      ];

      xdg.configFile."fontconfig/conf.d/50-omarchy.conf".source = pkgs.replaceVars (path {
        path = ../../config/fontconfig/fonts.conf;
      }) { font = config.omarchy.font.name; };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        name = "Adwaita";
        package = cfg._packages.adwaita-icon-theme;
        size = cursorSize;
      };
    })
  ];
}
