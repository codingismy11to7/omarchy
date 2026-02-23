#!/bin/bash

# Prompt for user account details: username, password, full name, email, hostname, timezone

clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Let's setup your user account..."
echo

# Username
while true; do
  OMARCHY_USER_NAME=$(gum input --header "Username" --placeholder "Alphanumeric without spaces (like dhh)" --padding "0 0 0 $PADDING_LEFT")

  if [ -z "$OMARCHY_USER_NAME" ]; then
    continue
  elif [[ ! "$OMARCHY_USER_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Username must be alphanumeric without spaces"
    continue
  fi

  break
done
export OMARCHY_USER_NAME

# Password
while true; do
  OMARCHY_PASSWORD=$(gum input --password --header "Password" --placeholder "Used for user + root + encryption" --padding "0 0 0 $PADDING_LEFT")

  if [ -z "$OMARCHY_PASSWORD" ]; then
    continue
  fi

  CONFIRM=$(gum input --password --header "Confirm" --placeholder "Must match the password you just typed" --padding "0 0 0 $PADDING_LEFT")

  if [ "$OMARCHY_PASSWORD" != "$CONFIRM" ]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Passwords do not match, try again"
    continue
  fi

  break
done
export OMARCHY_PASSWORD

# Full name
OMARCHY_FULL_NAME=$(gum input --header "Full name" --placeholder "Used for git and unix" --padding "0 0 0 $PADDING_LEFT")
export OMARCHY_FULL_NAME

# Email
OMARCHY_USER_EMAIL=$(gum input --header "Email address" --placeholder "Used for git" --padding "0 0 0 $PADDING_LEFT")
export OMARCHY_USER_EMAIL

# Hostname
OMARCHY_HOSTNAME=$(gum input --header "Hostname" --placeholder "Alphanumeric without spaces (or return for 'omarchy')" --padding "0 0 0 $PADDING_LEFT")
if [ -z "$OMARCHY_HOSTNAME" ]; then
  OMARCHY_HOSTNAME="omarchy"
fi
export OMARCHY_HOSTNAME

# Timezone
OMARCHY_TIMEZONE=$(timedatectl list-timezones | gum choose --header "Timezone" --selected "America/New_York" --height 12)
if [ -z "$OMARCHY_TIMEZONE" ]; then
  OMARCHY_TIMEZONE="America/New_York"
fi
export OMARCHY_TIMEZONE

# Secrets passphrase
while true; do
  OMARCHY_SECRETS_PASSPHRASE=$(gum input --password --header "Secrets passphrase" --placeholder "Used to encrypt credentials for deploying configs to other machines" --padding "0 0 0 $PADDING_LEFT")

  if [ -z "$OMARCHY_SECRETS_PASSPHRASE" ]; then
    continue
  fi

  CONFIRM=$(gum input --password --header "Confirm" --placeholder "Must match the passphrase you just typed" --padding "0 0 0 $PADDING_LEFT")

  if [ "$OMARCHY_SECRETS_PASSPHRASE" != "$CONFIRM" ]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Passphrases do not match, try again"
    continue
  fi

  break
done
export OMARCHY_SECRETS_PASSPHRASE
