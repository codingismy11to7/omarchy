# Omarchy on NixOS

A faithful NixOS implementation of [Omarchy](https://omarchy.org), DHH's beautiful, modern, and opinionated Linux desktop experience. This project packages Omarchy as Nix flake modules, allowing declarative, reproducible configuration on NixOS.

## Features

- **14 themes** with automatic color coordination across all apps
- **Hyprland** tiling compositor with sensible defaults and vim-style bindings
- **40+ scripts** (`omarchy-*`) for screenshots, screen recording, app launching, and more
- **Walker** application launcher with theme integration
- **Waybar** status bar with custom indicators
- **Package overrides** - swap any dependency for your preferred alternative
- **Obsidian** theming that syncs to all your vaults
- **Voxtype** voice-to-text integration (optional)
- **Gaming support** with Steam and Heroic launcher (optional)

## Installation

### Prerequisites

- NixOS with flakes enabled
- Home Manager

### 1. Add the flake input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    omarchy = {
      url = "github:codingismy11to7/omarchy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
}
```

### 2. Configure binary cache (recommended)

```nix
# flake.nix
{
  nixConfig = {
    extra-substituters = [ "https://nix-cache.codingismy11to7.us/omarchy" ];
    extra-trusted-public-keys = [
      "omarchy:TRPnFp7RNU+BhR64bXpG61cNE7TlB53BAoc7wEmhzyE="
    ];
  };
}
```

### 3. Import the modules

**Home Manager** (required):

```nix
{
  imports = [ inputs.omarchy.homeManagerModules.default ];

  omarchy = {
    enable = true;
    theme = "tokyo-night";  # or any of the 14 themes
    terminal = "ghostty";   # ghostty, kitty, or alacritty
  };
}
```

**NixOS** (recommended for system integration):

```nix
{
  imports = [ inputs.omarchy.nixosModules.default ];

  omarchy = {
    enable = true;
    # Enables SDDM, Hyprland, Qt theming, etc.
  };
}
```

## Configuration

### Basic Options

```nix
omarchy = {
  enable = true;

  # Appearance
  theme = "tokyo-night";           # See themes/ directory for all options
  terminal = "ghostty";            # ghostty, kitty, or alacritty
  twelveHourClock = true;          # 12h vs 24h in waybar

  # Hyprland
  hyprland = {
    package = pkgs.hyprland;       # Use flake input for latest
    roundWindowCorners = false;
    widerWindowGaps = false;
    monitorConfig = "";            # Custom monitor configuration
    bindings = [ ];                # Additional keybindings
  };

  # Keyboard
  keyboard = {
    layout = "us";
    variant = null;
    options = "compose:caps";
  };

  # Screensaver
  screensaver = {
    activationMinutes = 2.5;
    lockMinutes = 2.5;
    screenOffDelaySeconds = 179;
  };

  # Apps
  obsidian.enable = true;          # Install Obsidian with theme sync
  passwordManager = "1password";   # For keybinding integration

  # Optional features
  voxtype = null;                  # Set to {} to enable voice-to-text
};
```

### Package Overrides

Override any package used by omarchy:

```nix
omarchy.packages = {
  jq = pkgs.jaq;                   # Use jaq instead of jq
  brave = pkgs.ungoogled-chromium; # Different browser for webapps
  obsidian = pkgs.obsidian;        # Pin a specific version
};
```

### Available Themes

Located in `themes/`: catppuccin-frappe, catppuccin-latte, catppuccin-macchiato, catppuccin-mocha, dracula, everforest, gruvbox-dark, gruvbox-light, kanagawa, nord, rose-pine, rose-pine-dawn, solarized, tokyo-night

### LazyVim Theme Integration

Export the current omarchy theme to your Neovim config:

```nix
# With nixPatch-nvim
home.packages = [
  (inputs.nvim.lib.mkNeovim {
    pkgs = pkgs;
    inherit (pkgs.stdenv.hostPlatform) system;
    theme.content = inputs.omarchy.lazyvimTheme.default { inherit config; };
  })
];
```

### Stylix Theme Export

For Stylix users, export the color palette:

```nix
stylix.base16Scheme = inputs.omarchy.stylixTheme.default { inherit config; };
```

## Architecture

```
nix/modules/
├── home-manager.nix     # Main home-manager module (imports all below)
├── nixos.nix            # System-level module (SDDM, Hyprland, Qt)
├── options/home.nix     # Central options definition
├── scripts/home.nix     # 40+ omarchy-* scripts
├── hyprland/            # Compositor configuration
├── waybar/              # Status bar
├── walker/              # App launcher
├── theme/               # Color templating
├── obsidian/            # Obsidian theming
├── voxtype/             # Voice-to-text
├── gaming/              # Steam, Heroic
└── ...                  # Terminal emulators, gtk, mako, etc.

default/                 # Template configs with @placeholder@ substitution
config/                  # User-overridable configs (sourced last)
themes/{name}/           # Color palettes and backgrounds
bin/                     # omarchy-* scripts
```

## Development

```bash
nix develop          # Enter dev shell (or use direnv)
lint                 # Run statix and deadnix
lint --fix           # Auto-fix lint issues
nix flake check      # Full build validation
```

## Current Status

This is a work in progress. The core desktop experience works well, but:

- **Some menu entries don't work** or show errors (features not yet implemented)
- **No OS updates/age tracking** - NixOS handles this differently anyway
- **Some scripts are stubs** - they exist but need NixOS-specific implementations
- **Limited testing** - primarily tested on one machine

Contributions welcome! Check the issues or just fix something that bugs you.

## Goals

- **Faithful reproduction** of the Omarchy desktop experience
- **Upstream alignment** via patches rather than reimplementation
- **Seamless integration** as a drop-in Home Manager module
- **NixOS idioms** where they make more sense than upstream patterns

## Non-Goals

- Total feature parity where it conflicts with NixOS idioms
- Support for non-flake configurations

## Installer ISO (Experimental)

There's an experimental NixOS installer ISO that provides a
guided installation experience similar to upstream Omarchy's
installer. It walks through keyboard layout, WiFi, account
setup, disk selection, and then runs a full NixOS installation
with omarchy pre-configured.

**This is very early and mostly just wires up
[my personal dotfiles](https://github.com/codingismy11to7/dotfiles).**
It's not yet a general-purpose omarchy installer — it clones
my dotfiles repo, strips out personal settings, and installs
from that. It works, but it's tightly coupled to my setup
for now.

To build the ISO:

```bash
nix develop
build-installer
```

The resulting ISO is in `result/iso/`. Boot it in a VM or
write it to a USB drive.

---

# Original README

# Omarchy

Omarchy is a beautiful, modern & opinionated Linux distribution by DHH.

Read more at [omarchy.org](https://omarchy.org).

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
