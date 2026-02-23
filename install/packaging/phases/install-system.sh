#!/bin/bash

# Phase 3: Partition disk and install NixOS (or nix build in test mode)

DOTFILES_DIR="/tmp/dotfiles"

if [[ -n "${OMARCHY_TEST_MODE:-}" ]]; then
  echo "TEST MODE: Running nix build instead of disko + nixos-install..."
  nix build "$DOTFILES_DIR#nixosConfigurations.$OMARCHY_HOSTNAME.config.system.build.toplevel" --no-link
  echo "TEST MODE: Build succeeded!"
else
  # Partition and format disk
  sudo nix run nixpkgs#disko -- \
    --mode destroy,format,mount \
    --flake "$DOTFILES_DIR#$OMARCHY_HOSTNAME" \
    --yes-wipe-all-disks

  # Install NixOS
  sudo nixos-install --flake "$DOTFILES_DIR#$OMARCHY_HOSTNAME" --no-root-password

  # Deploy age key to installed system
  sudo mkdir -p /mnt/var/lib/sops
  sudo cp /tmp/age-key.txt /mnt/var/lib/sops/age-keys.txt
  sudo chmod 440 /mnt/var/lib/sops/age-keys.txt

  # Point dotfiles flake at the user's local secrets path before committing
  sed -i "s|url = \"path:/tmp/secrets\"|url = \"path:/home/$OMARCHY_USER_NAME/secrets\"|" "$DOTFILES_DIR/flake.nix"

  # Commit changes to both repos
  git -C "$DOTFILES_DIR" add -A
  git -C "$DOTFILES_DIR" -c user.name="$OMARCHY_FULL_NAME" -c user.email="$OMARCHY_USER_EMAIL" \
    commit -m "Configure $OMARCHY_HOSTNAME for NixOS install"
  git -C "$DOTFILES_DIR" checkout -b "$OMARCHY_HOSTNAME"

  rm -rf /tmp/secrets/.git
  git -C /tmp/secrets init -b "$OMARCHY_HOSTNAME"
  git -C /tmp/secrets add -A
  git -C /tmp/secrets -c user.name="$OMARCHY_FULL_NAME" -c user.email="$OMARCHY_USER_EMAIL" \
    commit -m "Initialize secrets for $OMARCHY_HOSTNAME"

  # Copy dotfiles and secrets to user's home directory
  USER_HOME="/mnt/home/$OMARCHY_USER_NAME"
  sudo mkdir -p "$USER_HOME"
  sudo cp -a "$DOTFILES_DIR" "$USER_HOME/dotfiles"
  sudo cp -a /tmp/secrets "$USER_HOME/secrets"

  sudo chown -R 1000:1000 "$USER_HOME/dotfiles" "$USER_HOME/secrets"
fi
