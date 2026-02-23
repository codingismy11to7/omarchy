source "@setupKeyboardSh@"
source "@setupWifiSh@"
source "@setupAccountSh@"

# Summary
if [ -n "$OMARCHY_KB_VARIANT" ]; then
  KB_DISPLAY="$OMARCHY_KB_VARIANT"
else
  KB_DISPLAY="$OMARCHY_KB_LAYOUT"
fi

clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Let's setup your user account..."
echo

TABLE=$(printf "| Field | Value |\n| --- | --- |\n| Username | %s |\n| Password | ****** |\n| Full name | %s |\n| Email address | %s |\n| Hostname | %s |\n| Timezone | %s |\n| Keyboard | %s |\n" \
  "$OMARCHY_USER_NAME" "$OMARCHY_FULL_NAME" "$OMARCHY_USER_EMAIL" "$OMARCHY_HOSTNAME" "$OMARCHY_TIMEZONE" "$KB_DISPLAY" \
  | mdcat)
gum style --padding "1 0 0 $PADDING_LEFT" "$TABLE"

echo
if ! gum confirm --padding "0 0 0 $PADDING_LEFT" --affirmative "Yes" --negative "No, change it" "Does this look right?"; then
  source "${BASH_SOURCE[0]}"
fi

source "@setupDiskSh@"
