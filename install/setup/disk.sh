#!/bin/bash

# Select installation target disk and confirm

clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Let's select where to install Omarchy..."
echo

# List whole disks (exclude loop, sr, ram devices), format as "/dev/xxx (SIZE)"
DISKS=$(lsblk -dpno NAME,SIZE | grep -v "loop\|sr\|ram\|zram" | while read -r name size; do
  echo "$name ($size)"
done)

if [ -z "$DISKS" ]; then
  gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "No disks found!"
  exit 1
fi

SELECTED=$(echo "$DISKS" | gum choose --header "Select install disk" --height 12)

if [ -z "$SELECTED" ]; then
  gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "No disk selected!"
  exit 1
fi

# Extract just the device path
OMARCHY_INSTALL_DISK=$(echo "$SELECTED" | awk '{print $1}')
export OMARCHY_INSTALL_DISK

echo
gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Everything will be overwritten. There is no recovery possible."
echo
if ! gum confirm --padding "0 0 0 $PADDING_LEFT" --affirmative "Yes, format disk" --negative "No, change it" "Confirm overwriting $OMARCHY_INSTALL_DISK"; then
  source "${BASH_SOURCE[0]}"
fi
