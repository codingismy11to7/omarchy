#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Omarchy locations
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"
export OMARCHY_INSTALL_LOG_FILE="/var/log/omarchy-install.log"
export PATH="$OMARCHY_PATH/bin:$PATH"

# Install
source "@helpersAll@"
source "@setupAll@"
source "@preflightAll@"
run_logged "@nixInstallSh@"
# source "$OMARCHY_INSTALL/packaging/all.sh"
# source "$OMARCHY_INSTALL/config/all.sh"
# source "$OMARCHY_INSTALL/login/all.sh"
source "@postInstallAll@"
