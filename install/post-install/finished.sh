stop_install_log

echo_in_style() {
  echo "$1" | @tte@ --canvas-width 0 --anchor-text c --frame-rate 640 print
}

clear
echo
@tte@ -i @logoPath@ --canvas-width 0 --anchor-text c --frame-rate 920 laseretch
echo

# Display installation time if available
if [[ -f $OMARCHY_INSTALL_LOG_FILE ]]; then
  TOTAL_TIME=$(tail -n 20 "$OMARCHY_INSTALL_LOG_FILE" | grep "^Total:" | sed 's/^Total:[[:space:]]*//' || true)
  if [[ -z $TOTAL_TIME ]]; then
    TOTAL_TIME=$(tail -n 20 "$OMARCHY_INSTALL_LOG_FILE" | grep "^Omarchy:" | sed 's/^Omarchy:[[:space:]]*//' || true)
  fi
fi

if [[ -n ${TOTAL_TIME:-} ]]; then
  echo
  echo_in_style "Installed in $TOTAL_TIME"
else
  echo_in_style "Finished installing"
fi

if sudo test -f /etc/sudoers.d/99-omarchy-installer; then
  sudo rm -f /etc/sudoers.d/99-omarchy-installer &>/dev/null
fi

# Exit gracefully if user chooses not to reboot
if @gum@ confirm --padding "0 0 0 $((PADDING_LEFT + 32))" --show-help=false --default --affirmative "Reboot Now" --negative "" ""; then
  # Clear screen to hide any shutdown messages
  clear

  if [[ -n ${OMARCHY_CHROOT_INSTALL:-} ]]; then
    touch /var/tmp/omarchy-install-completed
    exit 0
  else
    sudo reboot 2>/dev/null
  fi
fi
