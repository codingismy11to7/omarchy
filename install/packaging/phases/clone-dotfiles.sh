#!/bin/bash

# Phase 1: Clone dotfiles, configure host, stage changes

DOTFILES_DIR="/tmp/dotfiles"
HOSTS_DIR="$DOTFILES_DIR/hosts"
HOST_DIR="$HOSTS_DIR/$OMARCHY_HOSTNAME"

# Clone dotfiles
if [ -d "$DOTFILES_DIR" ]; then
  rm -rf "$DOTFILES_DIR"
fi

git clone https://github.com/codingismy11to7/dotfiles.git "$DOTFILES_DIR"

# Set up host directory for this machine
find "$HOSTS_DIR" -maxdepth 1 -type f -delete
for dir in "$HOSTS_DIR"/*/; do
  [ "$(basename "$dir")" = "nixvm" ] && continue
  rm -rf "$dir"
done
mv "$HOSTS_DIR/nixvm" "$HOST_DIR"

# Create host config
cat > "$HOST_DIR/config.nix" <<EOF
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
OPTS="$DOTFILES_DIR/modules/options.nix"
CONSOLE_KEYMAP="${OMARCHY_KB_VARIANT:-$OMARCHY_KB_LAYOUT}"
sed -i "/consoleKeyMap/,/};/ s|default = \"dvorak\"|default = \"$CONSOLE_KEYMAP\"|" "$OPTS"
sed -i "/keyboardLayout/,/};/ s|default = \"us\"|default = \"$OMARCHY_KB_LAYOUT\"|" "$OPTS"
sed -i "/keyboardVariant/,/};/ s|default = \"dvorak\"|default = \"${OMARCHY_KB_VARIANT:-}\"|" "$OPTS"
sed -i "s|default = \"America/New_York\"|default = \"$OMARCHY_TIMEZONE\"|" "$OPTS"
sed -i "/username/,/};/ s|default = \"steven\"|default = \"$OMARCHY_USER_NAME\"|" "$OPTS"
sed -i "/fullName/,/};/ s|default = \"Steven Scott\"|default = \"$OMARCHY_FULL_NAME\"|" "$OPTS"
# Disable fish (unconditionally imported, no option to toggle)
sed -i 's|^\(\s*\./fish/core\.nix\)|# \1|' "$DOTFILES_DIR/modules/core.nix"
sed -i 's|^\(\s*\./fish/home\.nix\)|# \1|' "$DOTFILES_DIR/modules/home.nix"

# Clear personal syncthing device entries
sed -i '/syncthing\.devices/,/};/{/^[[:space:]]*".*=.*".*;$/d}' "$OPTS"
sed -i '/syncthing\.devices/,/};/{s/default = {/default = { # Add your syncthing devices here/}' "$OPTS"

# Update disko config: set disk name, device, and hostname
sed -i "s/nixorge/$OMARCHY_HOSTNAME/" "$HOST_DIR/disk-config.nix"
sed -i "s|/dev/vda|$OMARCHY_INSTALL_DISK|" "$HOST_DIR/disk-config.nix"

# Stage host directory changes so Nix flake can see them
git -C "$DOTFILES_DIR" add hosts/
