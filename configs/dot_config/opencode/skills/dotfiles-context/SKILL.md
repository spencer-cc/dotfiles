---
name: dotfiles-context
description: CRITICAL - Load for config file or package operations in the dotfiles repo. Covers chezmoi source paths (~/.config/* → ~/dotfiles/configs/), the Nix package/profile system, and deployment commands.
---

## Architecture

The dotfiles use a decoupled three-layer architecture. Never mix concerns between layers:

| Layer    | Tool                            | Scope                                                 | Source                |
| -------- | ------------------------------- | ----------------------------------------------------- | --------------------- |
| Configs  | chezmoi                         | Tool config files, templating, colorscheme            | `~/dotfiles/configs/` |
| Packages | Nix (Home Manager + nix-darwin) | CLI packages, fonts; macOS system settings + services | `~/dotfiles/nix/`     |
| Fallback | Homebrew (`Brewfile`)           | Packages on machines without Nix                      | `~/dotfiles/brew/`    |

Invariants:

- Packages are managed **only** in `nix/profiles/*.nix` — never added to chezmoi configs
- Home Manager profiles are **packages only** — no config files, no activation hooks (chezmoi owns configs)
- macOS system settings, launchd services, and brew casks live in nix-darwin modules (`nix/darwin/`)

## Dotfiles Structure (chezmoi layer)

All configuration files are managed with **chezmoi**. The source directory is `~/dotfiles/configs/`. Chezmoi deploys files to standard locations (`~/.config/`, `~/`, etc.) using `just dot apply`.

### Pattern

- **Source**: `~/dotfiles/configs/dot_config/<tool>/` (chezmoi `dot_` prefix maps to `~/.`)
- **Deployed to**: `~/.config/<tool>/` (and `~/dot_<file>` maps to `~/.<file>`)
- **Templates**: Files with `.tmpl` extension are Go templates processed by chezmoi
- **Data**: `~/dotfiles/configs/.chezmoidata/*.toml` provides template variables (`.colors.*` etc.)
- **Platform exclusion**: macOS-only tools are excluded on Linux via `.chezmoiignore.tmpl`
- **Discovery**: List `~/dotfiles/configs/dot_config/` (plus top-level `dot_*` files in `configs/`) to see which tools are currently managed — the tool set evolves, so don't assume from memory

### File Operations Rule

- **PREFER reading from** `~/dotfiles/configs/dot_config/<tool>/` over deployed locations (`~/.config/`, `~/`, etc.)
  - _Rationale: Source files are the canonical version. Deployed files are generated. Reading source avoids session boundary prompts._
- **Apply same pattern for writes**: Write to `~/dotfiles/configs/dot_config/<tool>/` rather than deployed locations
- Template files (`.tmpl`) contain Go template syntax (`{{ .colors.* }}`) — edit the template, not the deployed output
- After editing, run `just dot apply` to deploy changes

### Known Config Locations

The per-tool inventory changes over time, so treat this as a discovery step, not a memorized list:

```bash
ls ~/dotfiles/configs/              # top-level dot_* files + dot_config/
ls ~/dotfiles/configs/dot_config/   # per-tool config directories
cat ~/dotfiles/configs/.chezmoiignore.tmpl   # platform exclusions
```

### Chezmoi

Configs are deployed with chezmoi using `just dot apply` which runs `chezmoi apply --source ~/dotfiles/configs --force --keep-going`. The `dot_` prefix in source filenames maps to a dot in the deployed path (e.g., `dot_config` -> `.config`, `dot_bashrc` -> `.bashrc`).

## Nix (packages layer)

- **Flake entry**: `~/dotfiles/nix/flake.nix`; machine identity (`username`, `system`) in `nix/variables.nix` — edit per machine before deploying to a new host
- **Profiles**: `nix/profiles/*.nix` are Home Manager package sets, layered via `imports` (a base profile is imported by extended ones). Discover the current profiles by reading the directory — the set evolves
- **macOS**: the whole system (packages + system settings + services) deploys via the nix-darwin configuration; modules in `nix/darwin/` (`system.nix`, `services.nix`, `brew.nix`). Determinate manages Nix itself, not nix-darwin (`nix.enable = false`)
- **Linux**: deploys evaluate with `--impure` so the flake picks up `USER` and platform from the environment — no per-machine file edits. macOS uses pure eval via `variables.nix`

### Workflow

- Add a package: edit the relevant `nix/profiles/<profile>.nix`, then `just pack deploy <profile>`
- Deploy/build/rollback commands: run `just pack --list` or read `nix/nix.just` (recipes evolve; don't rely on memorized lists)
- On macOS the profile argument is ignored — nix-darwin manages everything via the `<username>-mac` flake key; `mac` is accepted as a no-op alias

## Brew fallback

`just brew install|update|list` against `~/dotfiles/brew/Brewfile` — for machines without Nix (e.g., university Linux). If you add a tool to a Nix profile that should also exist on non-Nix machines, add it to the Brewfile too.

## Commands

Justfile modules are defined in `~/dotfiles/.justfile`: `dot` (chezmoi), `pack` (nix), `brew` (fallback), plus tool modules (`nvim`, `skbar`). Run `just --list` / `just <mod> --list` for current recipes — this document intentionally does not enumerate them, as they change often.

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
- `~/dotfiles/docs/dotfiles-nix.md` — deploy commands, editing, rollback
- `~/dotfiles/docs/setup.md` — initial installation
- `~/dotfiles/docs/colorscheme.md` — full color token reference
