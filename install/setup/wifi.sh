#!/bin/bash

# Offer WiFi configuration if not already connected

if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
  return
fi

clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "No network connection detected."
echo

if gum confirm --padding "0 0 0 $PADDING_LEFT" --affirmative "Yes, configure WiFi" --negative "Skip" "Do you need to connect to WiFi?"; then
  nmtui connect
fi

# Verify connectivity
if ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
  gum style --foreground 1 --padding "1 0 0 $PADDING_LEFT" "Still no network connection. Installation requires internet access."
  echo
  if gum confirm --padding "0 0 0 $PADDING_LEFT" --affirmative "Try again" --negative "Continue anyway" "Retry network setup?"; then
    source "${BASH_SOURCE[0]}"
  fi
fi
