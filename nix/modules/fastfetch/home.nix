{ lib, pkgs, ... }:
with builtins;
{
  programs.fastfetch = {
    enable = true;
  };

  # NixOS variant of config/fastfetch/config.jsonc: upstream's version is driven by
  # Arch-only omarchy-version* scripts (git checkout, pacman mirrors and log).
  xdg.configFile."fastfetch/config.jsonc".source =
    pkgs.replaceVars (path { path = ./config.jsonc; })
      {
        version = lib.trim (readFile ../../../version);
      };
}
