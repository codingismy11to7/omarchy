{
  config,
  lib,
  ...
}:
let
  cfg = config.omarchy;
in
lib.mkIf cfg.git.enable {
  programs.git = {
    enable = true;
    package = cfg._packages.git;

    settings = {
      user = {
        name = cfg.git.userName;
        email = cfg.git.userEmail;
      };

      pull.rebase = true;
      push.default = "simple";
    };
  };
}
