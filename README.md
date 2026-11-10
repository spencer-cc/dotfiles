# My Configuration

Personal dotfiles using a decoupled architecture: **chezmoi** for config deployment with colorscheme templating, and **Homebrew** for packages (categorized Brewfiles) plus declarative macOS system defaults and launchd services.

## File Structure

```
dotfiles/
├── configs/                # Chezmoi source dir (config files + templates)
│   ├── .chezmoidata/       # Static data (colors.toml — active theme)
│   ├── themes/             # Theme files (catppuccin-mocha, circadia-dark-classic)
│   ├── dot_config/         # Tool configs (nvim, nushell, ghostty, git, etc.)
│   ├── dot_config/launchd/ # launchd service plists (sketchybar, aerospace, ...)
│   ├── run_onchange_mac-defaults.sh   # macOS system defaults (applied on change)
│   ├── run_onchange_reload-launchd.sh # syncs + restarts launchd services
│   └── *.tmpl              # Go templates with color/theme substitution
├── brew/                   # Categorized Brewfiles + brew just module
├── scripts/                # sys.just (Touch ID sudo), dir-tidy.nu
├── docs/                   # Documentation
└── wallpapers/             # Visual assets
```

- `configs/` — Config files, plists, and defaults deployed by chezmoi to `~/.config/` and `~/`
- `brew/Brewfile*` — Package groups: core, dev, desktop, security
- `run_onchange_*` — Applied by `just dot apply`: system defaults + service reloads

## Quick Start

```bash
git clone <dotfiles-url> && cd dotfiles
just brew install    # packages (or per group: just brew install dev)
just dot init        # once: prompts for git name/email
just dot apply       # configs + macOS defaults + launchd services
just sys touchid     # Touch ID for sudo
```

## Commands

| Command                 | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `just dot apply`        | Deploy configs + defaults + services             |
| `just dot theme <name>` | Switch colorscheme theme                         |
| `just brew install`     | Install all package groups                       |
| `just brew install dev` | Install one group (core\|dev\|desktop\|security) |
| `just sys touchid`      | Enable Touch ID for sudo                         |

## Documentation

- [Setup](./docs/setup.md) - Initial installation
- [Packages & System](./docs/packages.md) - Brewfile groups, launchd services, macOS defaults
- [Colorscheme](./docs/colorscheme.md) - Color palette reference and theme switching
- [Yubikey](./docs/yubikey.md) - Yubikey setup and SSH usage
- [Karabiner](./docs/karabiner.md) - Key remapping design and sync workflow
