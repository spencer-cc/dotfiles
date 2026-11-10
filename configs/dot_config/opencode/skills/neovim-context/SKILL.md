---
name: neovim-context
description: Neovim configuration details including plugin management and language tools
---

## Config Location

`~/dotfiles/configs/dot_config/nvim/` (chezmoi source; deployed to `~/.config/nvim/` by `just dot apply`)

## Gaining Context

**ALWAYS read this README when working with this config:**

1. `~/dotfiles/configs/dot_config/nvim/README.md` - Overview of plugins, UI, navigation, and language tooling

## Structure

```
init.lua               # Entry point
lua/
├── core/              # options, keymaps, autocmds, filetypes
├── colorscheme/       # palette (chezmoi-templated)
├── helpers/           # shared utilities
├── lang-system/       # Language tool management
│   ├── init.lua       # Entry point; :LanguageInstall etc.; sets up Mason, treesitter, LSP
│   ├── lsp_actions.lua
│   └── plugin/init.lua
└── plugins/           # lazy.nvim plugin specs
    ├── lang-system.lua  # Language definitions (declarative table)
    ├── theme.lua, markdown/, snacks/, ui/, ux/
```

## Plugin Management

- Uses `lazy.nvim` for plugin management
- Aims for blazing fast boot times via lazy loading

## Language System

Declarative language configuration that centralizes:

- Treesitter
- LSP
- Formatter
- Linter
- DAP

### Key Commands

| Command                   | Description                      |
| ------------------------- | -------------------------------- |
| `:LanguageInstall [name]` | Install tools for a language     |
| `:LanguageInstallCurrent` | Install tools for current buffer |
| `:LanguageList`           | List all defined languages       |
| `:LanguageStatus`         | Show installation status         |
| `:AutoFormatToggle`       | Toggle format-on-save            |

### Adding Languages

Languages are defined in `lua/plugins/lang-system.lua` with schema:

```lua
lang_name = {
  filetypes = { "ext" },
  treesitter = "parser",
  lsp = { name = "server", mason = true },
  formatter = { name = "tool", mason = true },
  linter = { name = "tool", mason = true },
  dap = { ... },
}
```

## Editor Alias

The alias `e` opens neovim.
