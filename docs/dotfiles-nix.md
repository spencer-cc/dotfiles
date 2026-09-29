# Dotfiles Management

Configuration files are deployed with **chezmoi** (Go templates + colorscheme system). Packages are managed with **Nix** (nix-darwin + Home Manager) or **brew** as fallback. Config deployment and package management are fully decoupled.

## Architecture

- **chezmoi**: Config deployment only — templates in `configs/` deployed to `~/.config/` and `~/`
- **Nix (Home Manager)**: Packages only — no config files, no activation hooks. Profiles in `nix/profiles/`
- **nix-darwin**: macOS system settings, launchd services, brew management. Modules in `nix/darwin/`
- **Brew (Brewfile)**: Fallback package installation for machines without Nix (e.g., university Linux)

## Directory Structure

```
dotfiles/
├── configs/                    # Chezmoi source dir
│   ├── .chezmoidata/colors.toml # Active theme (swappable via `just dot theme`)
│   ├── themes/                  # Theme files (catppuccin-mocha, circadia-dark-classic)
│   ├── dot_config/              # Tool configs (*.tmpl for templated files)
│   └── *.tmpl                   # Go templates with color substitution
├── nix/
│   ├── flake.nix                # Flake entry point (HM profiles + nix-darwin)
│   ├── variables.nix           # Username + system platform
│   ├── profiles/               # Package profiles (packages only, no configs)
│   │   ├── minimal.nix          # Barebones POSIX + nushell
│   │   ├── default.nix          # Dev workstation
│   │   ├── security.nix         # Security/forensics toolkit
│   │   └── macos.nix            # macOS desktop (darwin profile)
│   ├── darwin/                  # nix-darwin modules (system, services, brew)
│   ├── nix.just                 # Justfile module for Nix commands
│   └── ../scripts/setup-nix.sh  # Linux bootstrap (Nix + HM profile)
├── data/Brewfile               # Fallback package list
├── dot.just                    # Chezmoi commands
├── brew.just                   # Brew commands
└── docs/                       # Documentation
```

## Profiles

| Profile    | Target                           | Deployment                  |
| ---------- | -------------------------------- | --------------------------- |
| `minimal`  | SSH servers, containers, rescue  | `just pack deploy minimal`  |
| `default`  | Dev workstation (Linux or macOS) | `just pack deploy default`  |
| `security` | Security/forensics toolkit       | `just pack deploy security` |
| `macos`    | macOS desktop (full system)      | `just pack deploy mac`      |

## Deploy Commands

### Configs (chezmoi — works on all platforms)

```bash
just dot apply          # Deploy configs via chezmoi
just dot diff           # Show diff between source and applied
just dot edit           # Open chezmoi source for editing
just dot update         # Git pull + reapply
just dot theme <name>   # Switch colorscheme theme
```

### Packages (Nix)

```bash
# Deploy macOS (full system: packages + system settings + services)
just pack deploy mac

# Deploy standalone HM profile
just pack deploy default
just pack deploy minimal

# Dry-run build
just pack dry mac

# Rollback
just pack rollback mac

# List generations
just pack generations

# Update flake inputs
just pack update

# Garbage collect (keep last 5 days)
just pack gc
```

### Packages (Brew fallback — for non-Nix machines)

```bash
just brew install       # Install from Brewfile
just brew update        # Update brew packages
just brew list          # List installed packages
```

## Colorscheme System

Theme colors come from `configs/.chezmoidata/colors.toml` (the active theme). Chezmoi templates reference `.colors.*` tokens. Switching themes swaps this file and re-applies:

```bash
just dot theme catppuccin-mocha
just dot theme circadia-dark-classic
```

Theme files live in `configs/themes/`. See [colorscheme.md](./colorscheme.md) for the full token reference.

## Editing Configs

Configs live in `configs/dot_config/<tool>/`. Template files use `.tmpl` extension with Go template syntax. After editing:

```bash
just dot apply    # Re-deploy
```

For Nix packages, edit `nix/profiles/<profile>.nix` and redeploy:

```bash
just pack deploy <profile>
```
