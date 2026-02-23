#!/bin/bash

# Phase 2: Generate facter report, clone and initialize secrets, deploy age key

DOTFILES_DIR="/tmp/dotfiles"
HOSTS_DIR="$DOTFILES_DIR/hosts"
HOST_DIR="$HOSTS_DIR/$OMARCHY_HOSTNAME"

# Write encryption password
echo -n "$OMARCHY_PASSWORD" > /tmp/secret.key

# Generate hardware facter report
if [[ -n "${OMARCHY_TEST_MODE:-}" ]]; then
  FACTER_SOURCE="${OMARCHY_TEST_FACTER_JSON:-}"
  if [[ -n "$FACTER_SOURCE" && -f "$FACTER_SOURCE" ]]; then
    cp "$FACTER_SOURCE" "$HOST_DIR/facter.json"
  else
    echo "TEST MODE: No facter.json provided, generating minimal stub"
    echo '{}' > "$HOST_DIR/facter.json"
  fi
else
  sudo nix run nixpkgs#nixos-facter -- --output "$HOST_DIR/facter.json"
  sudo chown nixos "$HOST_DIR/facter.json"
fi

# Clone and initialize secrets
if [ -d /tmp/secrets ]; then
  rm -rf /tmp/secrets
fi
git clone https://github.com/codingismy11to7/secrets.git /tmp/secrets

# Point dotfiles at local secrets clone
sed -i 's|url = "github:codingismy11to7/secrets"|url = "path:/tmp/secrets"|' "$DOTFILES_DIR/flake.nix"

# In test mode, point dotfiles at local omarchy checkout
if [[ -n "${OMARCHY_TEST_REPO:-}" ]]; then
  sed -i 's|url = "github:codingismy11to7/omarchy"|url = "path:'"$OMARCHY_TEST_REPO"'"|' "$DOTFILES_DIR/flake.nix"
  sed -i '/# url = "path:.*omarchy";/d' "$DOTFILES_DIR/flake.nix"
fi

# Replace personal omarchy settings with stock defaults
cat > "$DOTFILES_DIR/modules/omarchy/personal-core.nix" <<'NIXEOF'
{ ... }:
{
  # Stock omarchy defaults — customize after install
}
NIXEOF

cat > "$DOTFILES_DIR/modules/omarchy/personal-home.nix" <<'NIXEOF'
{ ... }:
{
  # Stock omarchy defaults — customize after install
}
NIXEOF

# Strip secrets modules down to only what init-secrets provides
cat > /tmp/secrets/nix/nixos.nix <<'NIXEOF'
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.secrets;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = cfg.sopsKeyFile;
      defaultSopsFile = builtins.path { path = ../secrets.yaml; };

      secrets = {
        unixPassword = mkIf cfg.users.enable {
          neededForUsers = true;
        };
        unixRootPassword = mkIf cfg.users.enable {
          neededForUsers = true;
        };
      };
    };

    environment.sessionVariables.SOPS_AGE_KEY_FILE = cfg.sopsKeyFile;

    users = mkIf cfg.users.enable {
      mutableUsers = false;
      users = {
        root.hashedPasswordFile = config.sops.secrets.unixRootPassword.path;
        ${cfg.username}.hashedPasswordFile = config.sops.secrets.unixPassword.path;
      };
    };
  };
}
NIXEOF

cat > /tmp/secrets/nix/home-manager.nix <<'NIXEOF'
{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.secrets;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = cfg.sopsKeyFile;
      defaultSopsFile = ../secrets.yaml;
      secrets.sshPrivKey = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "0600";
      };
    };

    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.sopsKeyFile;
  };
}
NIXEOF

nix develop /tmp/secrets --command init-secrets \
  --passphrase "$OMARCHY_SECRETS_PASSPHRASE" \
  --password "$OMARCHY_PASSWORD" \
  --ssh-comment "$OMARCHY_USER_NAME@$OMARCHY_HOSTNAME" \
  --dir /tmp/secrets \
  --no-install-key \
  --key-output /tmp/age-key.txt

# Make age key available for nixos-install
if [[ -z "${OMARCHY_TEST_MODE:-}" ]]; then
  sudo mkdir -p /var/lib/sops
  sudo cp /tmp/age-key.txt /var/lib/sops/age-keys.txt
  sudo chmod 440 /var/lib/sops/age-keys.txt
fi
