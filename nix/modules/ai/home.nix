{
  config,
  lib,
  omarchyInputs,
  pkgs,
  ...
}:
with builtins;
let
  inherit (lib) optionals;
  inherit (lib.modules) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;

  cfg = config.omarchy;
  inherit (cfg) ai;

  claudeCodePkgs = omarchyInputs.claude-code-nix.packages.${system};
  codexCliPkgs = omarchyInputs."codex-cli-nix".packages.${system};
in
mkIf (ai.claudeCode.enable || ai.codexCli.enable) {
  home.packages =
    with pkgs;
    optionals ai.claudeCode.enable [
      claudeCodePkgs.claude-code
      sox # enables voice input for claude
    ]
    ++ optionals ai.codexCli.enable [
      bubblewrap
      codexCliPkgs.codex
    ];
}
