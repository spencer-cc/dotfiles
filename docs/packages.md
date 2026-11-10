# Packages & System

Packages are managed with **Homebrew** via categorized Brewfiles. Configs are deployed with **chezmoi** — the two are fully decoupled.

## Brewfile Groups

| File                     | Contents                                                      |
| ------------------------ | ------------------------------------------------------------- |
| `brew/Brewfile`          | Core: shell, config tooling, essential CLI, fonts             |
| `brew/Brewfile.dev`      | Toolchains, LSPs, formatters, docs                            |
| `brew/Brewfile.desktop`  | GUI casks, window management (sketchybar/aerospace), hardware |
| `brew/Brewfile.security` | Optional forensics toolkit                                    |

## Commands

```bash
just brew install              # everything (core + dev + desktop + security)
just brew install dev          # one group: core|dev|desktop|security
just brew update               # upgrade all (or per group)
just brew check                # show missing entries
just brew list                 # list tracked packages
```

`brew bundle install` is idempotent — safe to re-run; upgrades outdated entries.

## Adding a package

1. Find the right group (core = needed by configs; dev = development; desktop = GUI/services; security = forensics)
2. Add `brew "name"`, `cask "name"`, or `tap "user/repo"` to the file
3. `just brew install <group>`

Notes:

- Brewfiles install global toolchains only; per-project version pinning is out of scope (a version manager like `mise` would be the fallback)

## New Machine Setup

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Clone + packages
git clone <dotfiles-url> && cd dotfiles
just brew install

# 3. Configs (prompts for git name/email on first run)
just dot init
just dot apply    # also applies macOS defaults + launchd services
```

Post-deploy manual steps:

```bash
just sys touchid   # Touch ID for sudo (needs sudo)
```

- Sketchybar Full Disk Access: System Settings > Privacy & Security > Full Disk Access > add `/opt/homebrew/bin/sketchybar`
- Karabiner input monitoring permission on first launch

## macOS System Defaults

`configs/run_onchange_mac-defaults.sh` applies ~30 system settings (Finder, Dock, Spaces, trackpad, text correction, menu bar, screenshots). chezmoi re-runs it whenever the script changes (`just dot apply`). Toggling the same setting in System Settings will be overwritten on the next apply — edit the script instead.

Some settings (menu bar, trackpad) require logout to take effect.

## Launchd Services

Services are defined as plists in `configs/dot_config/launchd/` (labels: `io.github.felixkratz.sketchybar`, `com.github.nikitabobko.aerospace`, `io.github.felixkratz.borders`, `md.obsidian`, `local.dir-tidy`). On `just dot apply`, a `run_onchange` script syncs them to `~/Library/LaunchAgents` and restarts changed services.

```bash
launchctl list | grep -Ei 'aerospace|sketchybar|borders|obsidian|dir-tidy'
tail ~/Library/Logs/sketchybar.err   # service logs
```
