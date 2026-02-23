#!/bin/bash

# NixOS installation script

# Clone dotfiles
if [ -d /tmp/dotfiles ]; then
  rm -rf /tmp/dotfiles
fi

git clone https://github.com/codingismy11to7/dotfiles.git /tmp/dotfiles

# Set up host directory for this machine
cd /tmp/dotfiles/hosts
find . -maxdepth 1 -type f -delete
for dir in */; do
  [ "$dir" = "nixvm/" ] && continue
  rm -rf "$dir"
done
mv nixvm "$OMARCHY_HOSTNAME"

# Create host config
cat > "$OMARCHY_HOSTNAME/config.nix" <<EOF
{ config, ... }:
{
  dotfiles.personal = {
    gitEmail = "$OMARCHY_USER_EMAIL";
  };
  home-manager.users.\${config.dotfiles.personal.username} = {
    omarchy = {
      hyprland = {
        # uncomment for 16x9 monitors
        # dwindleExtra = "single_window_aspect_ratio = 4 3";

        # omarchy defaults to high-rez settings, delete or comment to go back to default
        monitorConfig = ''
          env = GDK_SCALE,1
          monitor = ,preferred,auto,1
        '';
      };
    };
  };
}
EOF

# Update defaults in options.nix
OPTS=/tmp/dotfiles/modules/options.nix
CONSOLE_KEYMAP="${OMARCHY_KB_VARIANT:-$OMARCHY_KB_LAYOUT}"
sed -i "/consoleKeyMap/,/};/ s|default = \"dvorak\"|default = \"$CONSOLE_KEYMAP\"|" "$OPTS"
sed -i "/keyboardLayout/,/};/ s|default = \"us\"|default = \"$OMARCHY_KB_LAYOUT\"|" "$OPTS"
sed -i "/keyboardVariant/,/};/ s|default = \"dvorak\"|default = \"${OMARCHY_KB_VARIANT:-}\"|" "$OPTS"
sed -i "s|default = \"America/New_York\"|default = \"$OMARCHY_TIMEZONE\"|" "$OPTS"
sed -i "/username/,/};/ s|default = \"steven\"|default = \"$OMARCHY_USER_NAME\"|" "$OPTS"
sed -i "/fullName/,/};/ s|default = \"Steven Scott\"|default = \"$OMARCHY_FULL_NAME\"|" "$OPTS"
sed -i "/fish = lib/,/};/ s|default = true|default = false|" "$OPTS"
sed -i "/syncthing.enable = lib/,/};/ s|default = true|default = false|" "$OPTS"

# Update disko config: set disk name, device, and hostname
sed -i "s/nixorge/$OMARCHY_HOSTNAME/" "$OMARCHY_HOSTNAME/disk-config.nix"
sed -i "s|/dev/vda|$OMARCHY_INSTALL_DISK|" "$OMARCHY_HOSTNAME/disk-config.nix"

# Stage host directory changes so Nix flake can see them
git -C /tmp/dotfiles add hosts/

# Write encryption password
echo -n "$OMARCHY_PASSWORD" > /tmp/secret.key

# Generate hardware facter report
sudo nix run nixpkgs#nixos-facter -- --output "$OMARCHY_HOSTNAME/facter.json"
sudo chown nixos "$OMARCHY_HOSTNAME/facter.json"

# Clone and initialize secrets
if [ -d /tmp/secrets ]; then
  rm -rf /tmp/secrets
fi
git clone https://github.com/codingismy11to7/secrets.git /tmp/secrets

# Point dotfiles at local secrets clone
sed -i 's|url = "github:codingismy11to7/secrets"|url = "path:/tmp/secrets"|' /tmp/dotfiles/flake.nix

# Strip personal omarchy settings from dotfiles modules
cat > /tmp/dotfiles/modules/omarchy/core.nix <<'NIXEOF'
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles;
  inherit (cfg) headless;
  inherit (cfg.personal) username;
  inherit (lib) mkIf;
in
{
  imports = [
    inputs.omarchy.nixosModules.default
  ];

  omarchy = {
    enable = !headless;
    hyprland = {
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
    };
    inherit username;
  };
}
NIXEOF

cat > /tmp/dotfiles/modules/omarchy/home.nix <<'NIXEOF'
{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = osConfig.dotfiles;
  inherit (lib) mkDefault mkIf;
  inherit (cfg) headless keyboardLayout keyboardVariant;
  browserPkg = pkgs.unstable.${cfg.browser};
in
{
  imports = [
    inputs.omarchy.homeManagerModules.default
  ];

  omarchy = {
    git = {
      userName = mkDefault cfg.personal.fullName;
      userEmail = mkDefault cfg.personal.gitEmail;
    };

    hyprland = {
      enable = !headless;
      package = mkDefault pkgs.unstable.hyprland;
    };
    terminal = if headless then null else mkDefault "ghostty";

    theme = mkDefault cfg.omarchyTheme;
    firstRunMode = mkDefault true;
    browser.webapp = mkIf (!headless) (mkDefault (config.omarchy.browser.wrapWithExtension browserPkg));
    keyboard = {
      layout = mkDefault keyboardLayout;
      variant = mkDefault keyboardVariant;
    };
    packages = mkIf headless {
      imv = null;
      mpv = null;
      swayosd = null;
    };
  };
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
sudo mkdir -p /var/lib/sops
sudo cp /tmp/age-key.txt /var/lib/sops/age-keys.txt
sudo chmod 440 /var/lib/sops/age-keys.txt

# Partition and format disk
sudo nix run nixpkgs#disko -- \
  --mode destroy,format,mount \
  --flake /tmp/dotfiles#"$OMARCHY_HOSTNAME" \
  --yes-wipe-all-disks

# Install NixOS
sudo nixos-install --flake /tmp/dotfiles#"$OMARCHY_HOSTNAME" --no-root-password

# Deploy age key to installed system
sudo mkdir -p /mnt/var/lib/sops
sudo cp /tmp/age-key.txt /mnt/var/lib/sops/age-keys.txt
sudo chmod 440 /mnt/var/lib/sops/age-keys.txt

# Copy dotfiles and secrets to user's home directory
USER_HOME="/mnt/home/$OMARCHY_USER_NAME"
sudo mkdir -p "$USER_HOME"
sudo cp -a /tmp/dotfiles "$USER_HOME/dotfiles"
sudo cp -a /tmp/secrets "$USER_HOME/secrets"

# Point dotfiles flake at the user's local secrets path
sudo sed -i "s|url = \"path:/tmp/secrets\"|url = \"path:/home/$OMARCHY_USER_NAME/secrets\"|" "$USER_HOME/dotfiles/flake.nix"

sudo chown -R 1000:1000 "$USER_HOME/dotfiles" "$USER_HOME/secrets"
