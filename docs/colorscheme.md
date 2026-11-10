# Colorscheme

Palette-based theming system inspired by [Omarchy](https://github.com/basecamp/omarchy) and [Circadia](https://tanmaymanojgandhi.github.io/circadia/).

A single file (`.chezmoidata/colors.toml`) defines all colors. All tool configs reference semantic tokens from this file via chezmoi templates. To switch themes, swap the file and reapply.

## Theme Switching

Theme files live in `configs/themes/`. Each is a complete `colors.toml` with all sections filled in.

```bash
cp configs/themes/catppuccin-mocha.toml configs/.chezmoidata/colors.toml
just dot apply
```

Switching is a manual two-step: copy the theme file over `.chezmoidata/colors.toml`, then apply (commit the copied file to make the switch stick).

To create a new theme, copy an existing theme file and modify the hex values.

## Token Structure

### Base palette (`[colors.palette]`)

14 raw color hues — the source of truth for all accent colors. Used by catppuccin compat, btop graphs, and ANSI palette.

| Key      | Hex       |
| -------- | --------- |
| coral    | `#f3b8b0` |
| salmon   | `#f0aaaa` |
| pink     | `#ee9dd4` |
| purple   | `#c490f0` |
| red      | `#ee668c` |
| red_soft | `#e67c92` |
| orange   | `#f59a64` |
| yellow   | `#f0d57c` |
| green    | `#8ae28e` |
| teal     | `#6addca` |
| cyan     | `#6cd2ea` |
| azure    | `#67c0ea` |
| blue     | `#7aacf9` |
| lilac    | `#a29ffb` |

### Core UI (`[colors.ui]`)

Backgrounds, foregrounds, borders, surfaces, accent, cursor. Maps to Neovim highlight groups (Normal, CursorLine, Pmenu, etc.) and terminal UI elements.

| Key            | Hex       | Purpose                       |
| -------------- | --------- | ----------------------------- |
| bg             | `#1E1E1E` | Main background               |
| bg_alt         | `#141414` | Sidebars, inactive panes      |
| bg_deep        | `#0A0A0A` | Popups, cursor line           |
| bg_catppuccin  | `#1e1e2e` | Ghostty terminal background   |
| fg             | `#cdd6f4` | Primary text                  |
| fg_secondary   | `#bac2de` | Secondary text                |
| fg_muted       | `#a6adc8` | Line numbers, status bar      |
| fg_faint       | `#9399b2` | Whitespace, fold guides       |
| border         | `#7f849c` | Split borders                 |
| border_muted   | `#6c7086` | Dimmer borders                |
| surface        | `#45475a` | Selection bg, raised elements |
| surface_raised | `#585b70` | Inactive selected line        |
| surface_sunken | `#313244` | Cursor line, popups           |
| accent         | `#cba6f7` | Focus rings, active borders   |
| cursor         | `#CBD6F7` | Terminal cursor               |
| meter_bg       | `#282828` | btop meter background         |
| find_highlight | `#3e5767` | bat search highlight          |

### ANSI 16-color palette (`[colors.ansi]`)

Standard terminal ANSI colors (0-15). Used by ghostty and other terminal emulators.

| Key            | ANSI slot | Hex       |
| -------------- | --------- | --------- |
| black          | 0         | `#313244` |
| red            | 1         | `#ee668c` |
| green          | 2         | `#8ae28e` |
| yellow         | 3         | `#f0d57c` |
| blue           | 4         | `#7aacf9` |
| magenta        | 5         | `#ee9dd4` |
| cyan           | 6         | `#6addca` |
| white          | 7         | `#cdd6f4` |
| bright_black   | 8         | `#45475a` |
| bright_red     | 9         | `#e84070` |
| bright_green   | 10        | `#6de07a` |
| bright_yellow  | 11        | `#e8c84a` |
| bright_blue    | 12        | `#6aa4f8` |
| bright_magenta | 13        | `#e878c0` |
| bright_cyan    | 14        | `#40d8c0` |
| bright_white   | 15        | `#bac2de` |

### Syntax (`[colors.syntax]`)

Treesitter-aligned tokens for code highlighting. Used by nvim (via catppuccin compat), bat, and starship.

| Key         | Hex       | Treesitter group                          |
| ----------- | --------- | ----------------------------------------- |
| keyword     | `#c490f0` | `@keyword`, `@conditional`, `@repeat`     |
| type        | `#f0d57c` | `@type`, `@type.builtin`                  |
| function    | `#7aacf9` | `@function`, `@function.call`, `@method`  |
| property    | `#6addca` | `@property`, `@field`, `@variable.member` |
| variable    | `#cdd6f4` | `@variable`, `@variable.parameter`        |
| string      | `#8ae28e` | `@string`, `@string.regex`                |
| number      | `#f59a64` | `@number`, `@boolean`                     |
| tag         | `#7aacf9` | `@tag`, `@tag.delimiter`                  |
| comment     | `#9399b2` | `@comment`                                |
| operator    | `#6addca` | `@operator`                               |
| punctuation | `#9399b2` | `@punctuation.*`                          |
| constant    | `#f59a64` | `@constant`                               |
| preproc     | `#f0d57c` | `@preproc`                                |
| constructor | `#c490f0` | `@constructor`                            |
| namespace   | `#f0d57c` | `@namespace`, `@module`                   |

### Markup (`[colors.markup]`)

Markdown/prose highlighting. Used by bat and nvim render-markdown.

| Key           | Hex       |
| ------------- | --------- |
| heading_1     | `#ee668c` |
| heading_2     | `#f59a64` |
| heading_3     | `#f0d57c` |
| heading_4     | `#8ae28e` |
| heading_5     | `#67c0ea` |
| heading_6     | `#a29ffb` |
| bold          | `#ee668c` |
| italic        | `#ee668c` |
| strikethrough | `#a6adc8` |
| link          | `#7aacf9` |
| raw           | `#8ae28e` |
| quote         | `#ee9dd4` |
| list_marker   | `#6addca` |

### Diagnostics (`[colors.diagnostic]`)

| Key     | Hex       |
| ------- | --------- |
| error   | `#ee668c` |
| warning | `#f0d57c` |
| info    | `#7aacf9` |
| hint    | `#8ae28e` |

### Git (`[colors.git]`)

Starship prompt indicators and lazygit branch colors.

| Key          | Hex       |
| ------------ | --------- |
| branch       | `#f06040` |
| state        | `#f5906a` |
| modified     | `#e8c84a` |
| untracked    | `#6aa4f8` |
| staged       | `#6de07a` |
| stashed      | `#b080f0` |
| conflicted   | `#e84070` |
| deleted      | `#e84070` |
| ahead_behind | `#6de07a` |

### Diff (`[colors.diff]`)

Delta (git diff) and nvim diff/gitsigns colors.

| Key                  | Hex       | Purpose                         |
| -------------------- | --------- | ------------------------------- |
| minus                | `#660000` | Delta deletion bg               |
| minus_emph           | `#8b3030` | Delta deletion emphasis bg      |
| plus                 | `#0e2e1e` | Delta addition bg               |
| plus_emph            | `#1a4a2a` | Delta addition emphasis bg      |
| file                 | `#7aacf9` | Delta file header               |
| hunk                 | `#f0d57c` | Delta hunk header               |
| hint                 | `#9399b2` | Delta inline hints              |
| separator            | `#7f849c` | Delta blame separator           |
| blame_1              | `#3d3d4d` | Blame gradient (lightest)       |
| blame_2              | `#383846` |                                 |
| blame_3              | `#34343f` |                                 |
| blame_4              | `#303038` |                                 |
| blame_5              | `#2c2c31` | Blame gradient (darkest)        |
| nvim_add_bg          | `#1e3a1e` | nvim DiffAdd bg                 |
| nvim_change_bg       | `#3a3a1e` | nvim DiffChange bg              |
| nvim_delete_bg       | `#3a1e1e` | nvim DiffDelete bg              |
| gitsigns_change_bg   | `#4a3d1a` | Gitsigns change inline bg       |
| gitsigns_delete_bg   | `#5e1e2a` | Gitsigns delete inline bg       |
| gitsigns_delete_virt | `#2d2429` | Gitsigns delete virtual line bg |
| gitsigns_virt_lnum   | `#5c4555` | Gitsigns virtual line number fg |

### Starship (`[colors.starship]`)

Prompt-specific colors for starship.

| Key       | Hex       |
| --------- | --------- |
| spacer    | `#45475a` |
| timer     | `#e8c84a` |
| directory | `#6aa4f8` |
| clock     | `#5ab8e8` |
| memory    | `#ee8888` |
| nix_shell | `#b080f0` |

### Opacity (`[colors.opacity]`)

| Key        | Value  |
| ---------- | ------ |
| background | `0.95` |
| cursor     | `0.85` |

## NVim / Catppuccin Compatibility

The catppuccin nvim plugin is used as a highlight group engine — it maps ~3000 highlight groups across treesitter, LSP semantic tokens, diagnostics, and 15+ plugin integrations.

The `palette.lua.tmpl` template exports a `catppuccin` table that maps all 27 catppuccin internal names to values from `colors.toml`:

| Catppuccin name | Source              |
| --------------- | ------------------- |
| rosewater       | `palette.coral`     |
| flamingo        | `palette.salmon`    |
| pink            | `palette.pink`      |
| mauve           | `palette.purple`    |
| red             | `palette.red`       |
| maroon          | `palette.red_soft`  |
| peach           | `palette.orange`    |
| yellow          | `palette.yellow`    |
| green           | `palette.green`     |
| teal            | `palette.teal`      |
| sky             | `palette.cyan`      |
| sapphire        | `palette.azure`     |
| blue            | `palette.blue`      |
| lavender        | `palette.lilac`     |
| base            | `ui.bg`             |
| mantle          | `ui.bg_alt`         |
| crust           | `ui.bg_deep`        |
| text            | `ui.fg`             |
| subtext1        | `ui.fg_secondary`   |
| subtext0        | `ui.fg_muted`       |
| overlay2        | `ui.fg_faint`       |
| overlay1        | `ui.border`         |
| overlay0        | `ui.border_muted`   |
| surface2        | `ui.surface_raised` |
| surface1        | `ui.surface`        |
| surface0        | `ui.surface_sunken` |

All 27 colors are overridden per theme, so swapping `colors.toml` changes the entire nvim UI.

## Tool Reference

| Tool       | Template                                                              | Key sections used                                 |
| ---------- | --------------------------------------------------------------------- | ------------------------------------------------- |
| ghostty    | `ghostty/config.tmpl`, `ghostty/themes/colorscheme-normal.tmpl`       | `ui`, `ansi`, `opacity`                           |
| starship   | `starship.toml.tmpl`                                                  | `starship`, `git`, `ui.surface`                   |
| btop       | `btop/themes/catppuccin.theme.tmpl`                                   | `ui`, `syntax`, `palette`, `diagnostic`           |
| git/delta  | `git/config.tmpl`                                                     | `diff`, `diagnostic`, `syntax`, `ui`              |
| lazygit    | `lazygit/config.yml.tmpl`                                             | `syntax`, `ui`, `palette`                         |
| nushell    | `nushell/confs/colors.nu.tmpl`                                        | `palette`, `ui`                                   |
| nvim       | `nvim/lua/colorscheme/palette.lua.tmpl`, `nvim/lua/plugins/theme.lua` | `palette`, `ui`, `syntax`, `diagnostic`, `diff`   |
| bat        | `bat/themes/colorscheme.tmTheme.tmpl`                                 | `ui`, `syntax`, `palette`, `markup`, `diagnostic` |
| borders    | `borders/executable_bordersrc.tmpl`                                   | `ui.accent`, `ui.surface`                         |
| sketchybar | `sketchybar/executable_config.nu.tmpl`                                | `palette`, `ui`, `syntax`, `diagnostic`           |
