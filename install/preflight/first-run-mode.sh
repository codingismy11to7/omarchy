# Set first-run mode marker so we can install stuff post-installation
mkdir -p ~/.local/state/omarchy
touch ~/.local/state/omarchy/first-run.mode

# not doing all this on fedora, hopefully running
# the gtk command with sudo and having to put in
# your password doesn't break something
exit 0

# Setup sudo-less access for first-run
sudo tee /etc/sudoers.d/first-run >/dev/null <<EOF
Cmnd_Alias FIRST_RUN_CLEANUP = /bin/rm -f /etc/sudoers.d/first-run
Cmnd_Alias SYMLINK_RESOLVED = /usr/bin/ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl
$USER ALL=(ALL) NOPASSWD: /usr/bin/ufw
$USER ALL=(ALL) NOPASSWD: /usr/bin/ufw-docker
$USER ALL=(ALL) NOPASSWD: /usr/bin/gtk-update-icon-cache
$USER ALL=(ALL) NOPASSWD: SYMLINK_RESOLVED
$USER ALL=(ALL) NOPASSWD: FIRST_RUN_CLEANUP
EOF
sudo chmod 440 /etc/sudoers.d/first-run
