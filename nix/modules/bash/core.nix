{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;
in
lib.mkIf cfg.bash.enable {
  users.users.${cfg.username}.shell = cfg.bash.package;
  environment.pathsToLink = [ "/share/bash-completion" ];
}
