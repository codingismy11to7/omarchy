{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.omarchy;
  p = cfg._packages;
in
mkIf (cfg.enable && cfg.obsidian.enable) {
  home.packages = [ p.obsidian ];

  # Sync theme to Obsidian vaults on activation
  home.activation.syncObsidianTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${cfg.scripts.omarchy-theme-set-obsidian}/bin/omarchy-theme-set-obsidian || true
  '';
}
