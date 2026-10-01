# NEOVIM

## UI

### Snacks.nvim

All-in-one utility plugin providing:

- **Dashboard**: Startup screen with plugin load stats and quick actions
- **Explorer**: File browser (`<leader>e`)
- **Picker**: Fuzzy finder for files, buffers, grep, git, LSP symbols, diagnostics, marks, registers, keymaps, commands, help, undo history, colorschemes
- **Indent**: Indent guides with chunk highlighting
- **Notifier**: Notification UI with wrapped text
- **Scroll**: Smooth scrolling
- **Statuscolumn**: Line numbers, signs, fold markers
- **Words**: LSP reference highlighting with `]]`/`[[` navigation
- **Bigfile**: Automatic handling of large files
- **Quickfile**: Fast file loading
- **Toggle mappings**: `<leader>u` prefix for spell, wrap, relativenumber, diagnostics, conceal, treesitter, inlay hints, indent, readonly

### Noice

Enhanced UI for messages, cmdline, and popupmenu:

- Command palette preset (cmdline + popupmenu positioned together)
- LSP hover docs and signature help with borders
- Long messages sent to split

### Lualine

Custom statusline with:

- Mode indicator
- Filename with modified/readonly/newfile symbols
- Git diff stats
- Macro recording indicator (shows register when recording)
- SSH connection indicator
- Diagnostics (error, warn, hint, info)
- Progress percentage
- Clock

### Themes

Catppuccin-mocha (default) with transparent background. Also includes: gruvbox, rose-pine, everforest, melange, bg.nvim

### Highlighting

- **todo-comments**: Highlights TODO/FIX/XXX in comments, searchable via `<leader>st`/`<leader>sT`
- **nvim-colorizer**: Displays color codes inline (xterm colors, no CSS names)

### Git

- **gitsigns**: Git hunks in signcolumn

## UX

- **Commenting**: built-in `gc`/`gb` operators with ts-comments (treesitter-aware commentstrings)
- **mini.move**: Move text with Alt+hjkl
- **vim-sleuth**: Auto-detect indentation
- **vim-surround**: Surround text objects with brackets/quotes (visual-mode `S` is Flash Treesitter; use `gS` for visual surround)
- **minipairs**: Auto-pairing for brackets and quotes. Brackets pair only before space/EOL; quotes only open in whitespace contexts, close normally inside pairs
- **which-key**: Keybind discovery popup with Helix preset. Press `<leader>?` to show all keymaps. Groups: `<leader>f` (File), `<leader>g` (Git), `<leader>h` (Harpoon), `<leader>s` (Search), `<leader>u` (UI), `<leader>d` (Dev Tools), `<leader>M` (Markdown)
- **blink.cmp**: Autocompletion with LSP, snippets, buffer, path sources. C-k/C-j navigate, Tab/S-Tab select or jump snippets, CR confirms (no auto-select)
- **Harpoon (v2)**: Quick file marking for fast switching

| Key                 | Action                   |
| ------------------- | ------------------------ |
| `<leader>a`         | Add file to harpoon      |
| `<leader>H`         | Toggle harpoon menu      |
| `<leader>ha`        | Append file              |
| `<leader>hA`        | Prepend file             |
| `<leader>hd`        | Remove file              |
| `<leader>h[` / `h]` | Prev/next harpooned file |
| `<leader>1-9`       | Jump to harpooned file   |

## Navigation

### Snacks Pickers

| Key               | Action           |
| ----------------- | ---------------- |
| `<leader><space>` | Smart find files |
| `L`               | Buffer list      |
| `<leader>/`       | Grep             |
| `<leader>e`       | File explorer    |
| `<leader>fb`      | Buffers          |
| `<leader>fc`      | Find config file |
| `<leader>sf`      | Files            |
| `<leader>sr`      | Recent files     |
| `<leader>m`       | Marks            |
| `<leader>r`       | Registers        |
| `<leader>U`       | Undo history     |

### Markdown

- **render-markdown.nvim**: Pretty markdown rendering with heading blocks, checkboxes, code blocks
- **bullets.vim**: Automatic bullet lists, checkbox toggling (`<C-x>`), indentation (`<C-,>`/`<C-.>`)

### lazygit

Integrated via Snacks (`<leader>gg`).

## Language Tooling

The single source of truth for per-language tooling (LSP, formatter, linter,
treesitter parsers) is the `languages` table in
[lua/plugins/lang-system.lua](lua/plugins/lang-system.lua) — its header comment
documents the schema. Wiring lives in `lua/lang-system/init.lua`.

### LSP Keybinds

Buffer-local (active when an LSP server is attached). All LSP actions are
grouped in the `H` action picker — there are no `<leader>l` binds.

| Key | Action                        |
| --- | ----------------------------- |
| `J` | Diagnostic float under cursor |
| `K` | Hover                         |
| `H` | LSP action picker             |

`H` opens a picker of all LSP actions (code action, rename, hover,
definition/references, calls, symbols, diagnostics pickers, ...) with
right-aligned descriptions. Entries unsupported by the attached servers are
shown dimmed and won't run, so in non-LSP buffers it works as read-only
capability info. Diagnostics pickers are always available.

- `:LanguageInstall [lang]` installs a language's Mason packages + parsers (bare call opens a picker)
- Treesitter: highlighting + indentation via `vim.treesitter.start` (main branch API)
- Formatting: conform.nvim, format-on-save via `:AutoFormatToggle`/`<leader>uf`, `:Format` for manual
- Linting: nvim-lint, on save/insert-leave
- Uninstall/status: `:Mason`, `:LspInfo`, `:checkhealth`
