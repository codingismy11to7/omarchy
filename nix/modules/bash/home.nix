{
  config,
  lib,
  pkgs,
  omarchyInputs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  p = cfg._packages;
  optionalPkgs = [
    "eza"
    "fzf"
    "starship"
    "zoxide"
  ];
  bashFiles = [ "aliases" "envs" "functions" "init" "inputrc" "rc" "shell" ];

  inherit (lib) getExe optionalString;
  inherit (pkgs.stdenv.hostPlatform) system;

  tte = omarchyInputs.terminaltexteffects.packages.${system}.default;

  fastfetch = getExe p.fastfetch;
  fastfetchCmd =
    if cfg.bash.fastfetch.logo == null then
      fastfetch
    else
      "${fastfetch} --logo-height 23 --chafa ${cfg.bash.fastfetch.logo}";

  interactiveShellInit = ''
    ${optionalString cfg.bash.fastfetch.enable fastfetchCmd}

    ${optionalString cfg.bash.sshKeyPrompt ''
      if ! ${p.openssh}/bin/ssh-add -l > /dev/null 2>&1; then
        echo "SSH identity not found. Please run 'ssh-add' to add your key." | ${getExe tte} --frame-rate 300 wipe
      fi
    ''}
  '';
in
lib.mkIf cfg.bash.enable {
  programs.bash = {
    enable = true;
    initExtra = readFile (path { path = ../../../default/bashrc; }) + interactiveShellInit;
  };

  home.packages = map (name: pkgs.${name}) (filter (name: cfg.bash.${name}) optionalPkgs);

  xdg.dataFile = listToAttrs (
    map (name: {
      name = "omarchy/default/bash/${name}";
      value.source = path { path = ../../../default/bash + "/${name}"; };
    }) bashFiles
  );
}
