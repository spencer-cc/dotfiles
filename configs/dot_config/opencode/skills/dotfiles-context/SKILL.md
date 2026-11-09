---
name: dotfiles-context
description: CRITICAL - Load for config file or package operations in the dotfiles repo. Covers chezmoi source paths (~/.config/* → ~/dotfiles/configs/), the categorized Homebrew Brewfile system, launchd services, and macOS defaults.
---

# Skill: dotfiles-context

## Architecture

The dotfiles use a decoupled two-layer architecture. Never mix concerns between layers:

| Layer    | Tool     | Scope                                                                      | Source                |
| -------- | -------- | -------------------------------------------------------------------------- | --------------------- |
| Configs  | chezmoi  | Tool config files, templating, colorscheme, launchd plists, macOS defaults | `~/dotfiles/configs/` |
| Packages | Homebrew | CLI packages, fonts, casks — grouped into categorized Brewfiles            | `~/dotfiles/brew/`    |

Invariants:

- Packages are managed **only** in `brew/Brewfile*` — never added to chezmoi configs
- chezmoi owns configs, launchd plists (`configs/dot_config/launchd/`), and the macOS defaults script (`configs/run_onchange_mac-defaults.sh.tmpl`)
- Homebrew GUI apps/services that nix can't manage don't exist — brew manages everything

## Dotfiles Structure (chezmoi layer)

All configuration files are managed with **chezmoi**. The source directory is `~/dotfiles/configs/`. Chezmoi deploys files to standard locations (`~/.config/`, `~/`, etc.) using `just dot apply`.

### Pattern

- **Source**: `~/dotfiles/configs/dot_config/<tool>/` (chezmoi `dot_` prefix maps to `~/.`)
- **Deployed to**: `~/.config/<tool>/` (and `~/dot_<file>` maps to `~/.<file>`)
- **Templates**: Files with `.tmpl` extension are Go templates processed by chezmoi
- **Data**: `~/dotfiles/configs/.chezmoidata/*.toml` provides template variables (`.colors.*` etc.)
- **run_onchange scripts**: `configs/run_onchange_*.sh.tmpl` — executed by chezmoi on apply when their content (including plist hashes) changes: macOS defaults + launchd service reload
- **launchd plists**: `configs/dot_config/launchd/<label>.plist.tmpl` — deployed to `~/.config/launchd/`, synced to `~/Library/LaunchAgents` by the reload script (labels: sketchybar, aerospace, jankyborders, obsidian, dir-tidy)
- **Discovery**: List `~/dotfiles/configs/dot_config/` (plus top-level `dot_*` and `run_*` files in `configs/`) to see what is currently managed — the tool set evolves, so don't assume from memory

### Pattern exception: macOS defaults

System settings live in `configs/run_onchange_mac-defaults.sh` (idempotent `defaults write`). To change a macOS setting, edit that script and `just dot apply` — do NOT use System Settings (next apply reverts GUI changes). Menu bar/trackpad changes need logout.

### File Operations Rule

- **PREFER reading from** `~/dotfiles/configs/dot_config/<tool>/` over deployed locations (`~/.config/`, `~/`, etc.)
  - _Rationale: Source files are the canonical version. Deployed files are generated. Reading source avoids session boundary prompts._
- **Apply same pattern for writes**: Write to `~/dotfiles/configs/dot_config/<tool>/` rather than deployed locations
- Template files (`.tmpl`) contain Go template syntax (`{{ .colors.* }}`) — edit the template, not the deployed output
- After editing, run `just dot apply` to deploy changes

### Known Config Locations

The per-tool inventory changes over time, so treat this as a discovery step, not a memorized list:

```bash
ls ~/dotfiles/configs/              # top-level dot_*, run_onchange_* files + dot_config/
ls ~/dotfiles/configs/dot_config/   # per-tool config directories
cat ~/dotfiles/configs/.chezmoiignore.tmpl   # platform exclusions
```

### Chezmoi

Configs are deployed with chezmoi using `just dot apply` which runs `chezmoi apply --source ~/dotfiles/configs --force --keep-going`. The `dot_` prefix in source filenames maps to a dot in the deployed path (e.g., `dot_config` -> `.config`).

## Packages (Homebrew layer)

Packages are grouped into categorized Brewfiles so a new machine doesn't need everything at once:

| File                     | Contents                                                |
| ------------------------ | ------------------------------------------------------- |
| `brew/Brewfile`          | Core: shell, config tooling, essential CLI, fonts       |
| `brew/Brewfile.dev`      | Toolchains (python/node/go/rust/llvm), LSPs, formatters |
| `brew/Brewfile.desktop`  | GUI casks, sketchybar/aerospace, yubikey tools, taps    |
| `brew/Brewfile.security` | Optional forensics toolkit (nmap, hashcat, ghidra, ...) |

### Workflow

- Add a package: edit the relevant `brew/Brewfile*` (pick the right group), then `just brew install <group>`
- `just brew install` (no arg) = all groups; `just brew update|check|list` also support groups
- `brew bundle install` is idempotent and upgrades outdated entries

### Special cases

- `yubikey-manager` (ykman) is not in homebrew — install via `pipx install yubikey-manager`
- Per-project toolchain versions belong in project-local nix flakes (`nix develop`), not the Brewfile

## System tasks

- `just sys touchid` — enable Touch ID for sudo (writes `/etc/pam.d/sudo_local`, needs sudo)
- `just dot apply` — re-applies defaults + reloads changed launchd services

## Commands

Justfile modules are defined in `~/dotfiles/.justfile`: `dot` (chezmoi), `brew` (packages), `sys` (system tasks), plus tool modules (`nvim`, `skbar`). Run `just --list` / `just <mod> --list` for current recipes — this document intentionally does not enumerate them, as they change often.

## Colorscheme

Theme colors come from `~/dotfiles/configs/.chezmoidata/colors.toml` (the active theme). Theme files live in `~/dotfiles/configs/themes/`. Switch themes with `just dot theme <name>`.

### Token Structure

Templates reference `.colors.*` tokens organized in semantic sections (`.colors.palette.*`, `.colors.ui.*`, `.colors.syntax.*`, `.colors.ansi.*`, etc.). All keys use underscores (not hyphens) to avoid `{{ index }}` syntax in templates.

**Do not assume token names from memory** — read `colors.toml` directly, or see `~/dotfiles/docs/colorscheme.md` for the full reference with hex values and catppuccin compat mapping. The token set evolves as tools are added.

## Structure and Context

**ALWAYS** look for README.md files in configs, if present they will provide information about the design and use of the configuration

### This skill's source

This skill is itself part of the dotfiles repo. Its canonical source is `~/dotfiles/configs/dot_config/opencode/skills/dotfiles-context/SKILL.md` — edit there and run `just dot apply` to deploy. Do not edit `~/.config/opencode/skills/` directly.

### Deeper documentation

- `~/dotfiles/README.md` — architecture overview and quick start
- `~/dotfiles/docs/packages.md` — Brewfile groups, launchd services, macOS defaults
- `~/dotfiles/docs/setup.md` — initial installation
- `~/dotfiles/docs/colorscheme.md` — full color token reference

Base directory for this skill: /Users/scc/.config/opencode/skills/dotfiles-context
Relative paths in `scripts/`, `reference/` are relative to this base directory.
