#!/bin/bash

# Select keyboard layout using xkb rules data
# Requires: @awk@, @xkbRules@ (path to evdev.lst)

XKB_RULES="@xkbRules@"

# Build list: base layouts + common variants (like Dvorak, Colemak)
# Format: "Description|layout|variant"
CHOICES=$(@awk@ '
  /^! layout/ { in_layout=1; in_variant=0; next }
  /^! variant/ { in_layout=0; in_variant=1; next }
  /^! / { in_layout=0; in_variant=0; next }

  in_layout && /^  / {
    code = $1
    $1 = ""
    sub(/^[[:space:]]+/, "")
    desc = $0
    print desc "|" code "|"
  }

  in_variant && /^  / {
    variant = $1
    $1 = ""
    sub(/^[[:space:]]+/, "")
    # Format is "layout_code: Description"
    split($0, parts, ": ")
    layout_code = parts[1]
    desc = parts[2]
    if (desc != "") {
      print desc "|" layout_code "|" variant
    }
  }
' "$XKB_RULES" | sort -t'|' -k1,1)

# Extract just the descriptions for gum
DESCRIPTIONS=$(echo "$CHOICES" | @awk@ -F'|' '{print $1}')

clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Let's setup your machine..."
echo

SELECTED=$(echo "$DESCRIPTIONS" | gum choose --header "Select keyboard layout" --selected "English (US)" --height 12)

if [ -n "$SELECTED" ]; then
  # Look up the layout/variant codes for the selection
  MATCH=$(echo "$CHOICES" | @awk@ -F'|' -v sel="$SELECTED" '$1 == sel { print; exit }')
  KB_LAYOUT=$(echo "$MATCH" | @awk@ -F'|' '{print $2}')
  KB_VARIANT=$(echo "$MATCH" | @awk@ -F'|' '{print $3}')

  # Apply console keymap (console keymap names differ from xkb names,
  # e.g. xkb us/dvorak -> console keymap "dvorak")
  if [ -n "$KB_VARIANT" ]; then
    sudo loadkeys "$KB_VARIANT" 2>/dev/null \
      || sudo loadkeys "$KB_LAYOUT-$KB_VARIANT" 2>/dev/null \
      || sudo loadkeys "$KB_LAYOUT" 2>/dev/null \
      || true
  else
    sudo loadkeys "$KB_LAYOUT" 2>/dev/null || true
  fi

  # Export for later use by NixOS config generation
  export OMARCHY_KB_LAYOUT="$KB_LAYOUT"
  export OMARCHY_KB_VARIANT="$KB_VARIANT"

  gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Keyboard: $SELECTED"
fi
