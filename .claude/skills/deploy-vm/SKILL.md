---
name: deploy-vm
description: Deploy omarchy and dotfiles to a test VM and build
argument-hint: "[vm-ip] [dotfiles-path]"
allowed-tools: Bash(rsync:*), Bash(ssh:*), Read, Grep
---

Sync omarchy and dotfiles to the test VM and build.

Arguments: $ARGUMENTS
- First argument: VM IP address
- Second argument: Path to dotfiles repo on local machine

The omarchy path is the current working directory (this repo).

Steps:
1. Parse arguments. If VM IP or dotfiles path not provided, ask the user.
2. Check that `<dotfiles>/flake.nix` has a `url = "path:..."` pointing to the omarchy repo (not a github URL). If it's using github, warn the user and stop.
3. Rsync the omarchy repo (current directory) to the VM at the same path (include .git)
4. Rsync the dotfiles repo to the VM at the same path (include .git)
5. SSH to the VM and run `cd <dotfiles> && nix flake update omarchy && nh os build .`
