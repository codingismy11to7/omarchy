{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (builtins) path;

  cfg = config.omarchy;

  defaultKeyringScript = path { path = ../../../install/login/default-keyring.sh; };
in
mkIf cfg.hyprland.enable {
  services.gnome-keyring = {
    enable = true;
    package = cfg._packages.gnome-keyring;
  };

  home.activation.setupDefaultKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.local/share/keyrings/Default_keyring.keyring" ]; then
      run bash ${defaultKeyringScript}
    fi
  '';
}
