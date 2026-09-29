# My Configuration

Personal dotfiles using a decoupled architecture: **chezmoi** for config deployment with colorscheme templating, **Nix** (nix-darwin + Home Manager) for packages and macOS system settings, and **brew** as a fallback for machines without Nix.

## File Structure

```
dotfiles/
├── configs/                # Chezmoi source dir (config files + templates)
│   ├── .chezmoidata/       # Static data (colors.toml — active theme)
│   ├── themes/             # Theme files (catppuccin-mocha, circadia-dark-classic)
│   ├── dot_config/         # Tool configs (nvim, nushell, ghostty, git, etc.)
│   └── *.tmpl             # Go templates with color/theme substitution
├── nix/                    # Nix flake + profiles (packages only)
│   ├── flake.nix           # Flake entry point (HM + nix-darwin)
│   ├── variables.nix       # Username + system platform
│   ├── profiles/           # Package profiles (minimal, default, security, macos)
│   ├── darwin/             # nix-darwin modules (system, services, brew)
│   └── nix.just            # Justfile module for Nix commands
├── data/
│   └── Brewfile            # Fallback package list for non-Nix machines
├── docs/                   # Documentation
└── misc/                   # Wallpapers and visual assets
```

- `configs/` — Config files deployed to `~/.config/` by chezmoi (not Nix)
- `nix/profiles/` — Package lists for each machine type (no config deployment)
- `nix/darwin/` — macOS system settings, launchd services, brew management
- `data/Brewfile` — Install packages via brew when Nix is unavailable

## Quick Start

### macOS (Nix)

```bash
# Deploy full macOS system (packages + system settings + configs)
just pack deploy mac    # Nix packages + system settings
just dot apply          # Chezmoi configs
```

### Linux with Nix

```bash
# Bootstrap: install Nix (if needed) + deploy packages via Home Manager
./scripts/setup-nix.sh

# Deploy configs via chezmoi
just dot apply
```

### Linux without Nix (e.g., university machine)

```bash
# Install packages via Linuxbrew
just brew install
# Deploy configs via chezmoi
just dot apply
```

## Commands

| Command                      | Description                      |
| ---------------------------- | -------------------------------- |
| `just dot apply`             | Deploy configs via chezmoi       |
| `just dot theme <name>`      | Switch colorscheme theme         |
| `just pack deploy mac`       | Deploy macOS system via Nix      |
| `just pack deploy <profile>` | Deploy packages via Home Manager |
| `just brew install`          | Install packages from Brewfile   |

## Documentation

- [Setup](./docs/setup.md) - Initial installation
- [Colorscheme](./docs/colorscheme.md) - Color palette reference and theme switching
- [Dotfiles Management](./docs/dotfiles-nix.md) - Deploy commands, editing, rollback
- [Migration to Chezmoi](./docs/migration-to-chezmoi.md) - Architecture details
- [Yubikey](./docs/yubikey.md) - Yubikey setup and SSH usage
- [TDF](./docs/pdf-viewer.md) - TUI pdf viewer
