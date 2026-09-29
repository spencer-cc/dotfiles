# Setup

## macOS (Nix)

### Install Nix

Install Nix using the [Determinate Nix installer](https://github.com/DeterminateSystems/nix-installer):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

This installs Nix with flakes enabled and adds `~/.nix-profile/bin` to PATH via `/etc/paths.d/nix`.

### Install nix-darwin

Install `darwin-rebuild` (bootstrap tool, not declared in the flake):

```bash
nix profile install nix-darwin
```

### Deploy packages + system settings

```bash
# Build first to verify everything compiles
just pack build mac

# Deploy the full system (packages + settings + services)
just pack deploy mac
```

This activates:

- macOS system defaults (dark mode, dock settings, finder, trackpad, screenshots)
- Touch ID for sudo
- Nushell as login shell (via `~/.local/bin/nushell` launcher)
- launchd services (sketchybar, aerospace, jankyborders, obsidian)
- Homebrew casks and formulae

### Deploy configs

```bash
# Initialize chezmoi (prompts for username, git name, email — run once)
just dot init

# Deploy all configs via chezmoi
just dot apply
```

### Post-Deploy

#### Sketchybar Full Disk Access

Sketchybar's getfocus plugin requires Full Disk Access to read `~/Library/DoNotDisturb/DB/Assertions.json`:

1. System Settings > Privacy & Security > Full Disk Access
2. Add `sketchybar` (at `/opt/homebrew/bin/sketchybar`)

#### Karabiner-Elements

Grant Karabiner input monitoring permission on first launch:

1. System Settings > Privacy & Security > Input Monitoring
2. Enable Karabiner-Elements

## Linux with Nix

### Bootstrap (script)

On a fresh Linux machine, clone the repo and run the bootstrap script:

```bash
git clone <dotfiles-url> && cd dotfiles
./scripts/setup-nix.sh            # default profile
./scripts/setup-nix.sh minimal    # or: minimal | default | security
```

The script:

1. Installs Nix via the [Determinate Nix installer](https://github.com/DeterminateSystems/nix-installer) (skipped if `nix` is already on PATH):
   - systemd + sudo → multi-user install with daemon
   - sudo, no systemd (containers, WSL1) → single-user install, `--init none`
   - no root access → aborts (Nix requires `/nix` at the filesystem root; see [nix-portable](https://github.com/nix-community/nix-portable) for a rootless workaround)
2. Deploys the chosen package profile via Home Manager (no pre-installed HM CLI needed — it runs through `nix run`)

Linux deploys evaluate the flake with `--impure` so the username and platform are picked up from the environment — no per-machine file edits. On machines where your login isn't `scc`, profile keys resolve as `<login>-<profile>` automatically.

### Deploy configs

```bash
just dot init     # once: prompts for git name/email
just dot apply
```

PATH is handled by the deployed configs: the nushell launcher and `env.nu` prepend `~/.nix-profile/bin` on Linux.

### Manual bootstrap

Equivalent to the script, without the installer:

```bash
nix run home-manager -- switch --impure --flake "./nix#$USER-default" -b backup
```

Run from the repo root (`-b backup` preserves conflicting files).

## Linux without Nix (e.g., university machine)

```bash
# Install packages via Linuxbrew
just brew install

# Initialize chezmoi (prompts for username, git name, email — run once)
just dot init

# Deploy configs via chezmoi
just dot apply
```

### Linuxbrew setup

If Linuxbrew isn't on PATH yet:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

The `dot_bashrc` deploys a Linuxbrew detection block that runs this automatically for bash. For nushell, the `nushell.tmpl` launcher prepends `/home/linuxbrew/.linuxbrew/bin` to PATH.

## Next Steps

- [Dotfiles Management](./dotfiles-nix.md) - Deploy commands, config editing, rollback
- [Colorscheme](./colorscheme.md) - Color palette reference
- [SSH](./ssh.md) - SSH config structure and yubikey setup
