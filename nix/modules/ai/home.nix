{
  config,
  lib,
  omarchyInputs,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;

  cfg = config.omarchy;
  inherit (cfg) ai;

  claudeCodePkgs = omarchyInputs.claude-code-nix.packages.${system};
in
mkIf ai.claudeCode.enable {
  home.packages = with pkgs; [
    claudeCodePkgs.claude-code
    sox # enables voice input for claude
  ];
}
