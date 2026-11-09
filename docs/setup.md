# Setup

## macOS

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Install packages

```bash
git clone <dotfiles-url> && cd dotfiles
just brew install
```

### Deploy configs

```bash
just dot init     # once: prompts for git name/email
just dot apply    # configs + macOS defaults + launchd services
```

### Post-Deploy

```bash
just sys touchid   # Touch ID for sudo
```

#### Sketchybar Full Disk Access

Sketchybar's getfocus plugin requires Full Disk Access to read `~/Library/DoNotDisturb/DB/Assertions.json`:

1. System Settings > Privacy & Security > Full Disk Access
2. Add `sketchybar` (at `/opt/homebrew/bin/sketchybar`)

#### Karabiner-Elements

Grant Karabiner input monitoring permission on first launch:

1. System Settings > Privacy & Security > Input Monitoring
2. Enable Karabiner-Elements

## Next Steps

- [Packages & System](./packages.md) - Brewfile groups, services, defaults
- [Colorscheme](./colorscheme.md) - Color palette reference
- [SSH](./ssh.md) - SSH config structure and yubikey setup
