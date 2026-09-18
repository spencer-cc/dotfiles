--- Language System: per-language toolchain inventory + plugin specs.
---
--- The `languages` table below is the single source of truth for which
--- tools are used per language. The wiring lives in lua/lang-system/init.lua.
---
--- Schema:
---   filetypes = { "ft", ... }      -- filetypes where LSP/format/lint attach
---   treesitter = "p" | { "p", .. } -- parsers to install and highlight
---   lsp = "server"                 -- lspconfig server name (optional)
---   formatter = "executable"       -- conform formatter (optional)
---   linter = "executable"          -- nvim-lint linter (optional)
---   mason = { lsp = "pkg" | false, formatter = ..., linter = ... }
---                                  -- Mason package name when it differs from
---                                  -- the tool name (default: "_" -> "-");
---                                  -- false = managed outside Mason (nix, cargo)
---   config = { ... }               -- extra vim.lsp.config for the lsp server
---   formatter_args / linter_args   -- extra CLI arguments
---   lsp_enable / formatter_enable / linter_enable = false
---                                  -- defined + installable, but not wired
---
--- Install a language's tools with :LanguageInstall [name] (bare opens a picker).
--- Uninstall/status via :Mason, :LspInfo, :checkhealth.

local lang_system = require("lang-system")

local languages = {
  ---- DOTFILES PARSER BUNDLE (no filetypes; parsers only) ----

  configs_group = {
    treesitter = {
      "ini",
      "git_config",
      "gitattributes",
      "gitignore",
      "editorconfig",
      "dockerfile",
      "ssh_config",
      "diff",
      "xml",
      "comment",
    },
  },

  ---- LANGUAGE DEFINITIONS ----

  regex = {
    treesitter = "regex",
  },

  lua = {
    filetypes = { "lua" },
    treesitter = "lua",
    lsp = "lua_ls",
    mason = { lsp = "lua-language-server" },
    formatter = "stylua",
    config = {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
        },
      },
    },
  },

  python = {
    filetypes = { "python", "py" },
    treesitter = "python",
    lsp = "basedpyright",
  },

  html = {
    filetypes = { "html" },
    treesitter = "html",
  },

  typescript = {
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "tsx", "jsx" },
    treesitter = { "typescript", "tsx", "javascript", "jsdoc" },
    lsp = "ts_ls",
    mason = { lsp = "typescript-language-server" },
    formatter = "prettier",
  },

  java = {
    filetypes = { "java" },
    treesitter = "java",
    lsp = "jdtls",
    -- No external formatter: jdtls's built-in Eclipse JDT formatter handles
    -- formatting (respects project .settings/org.eclipse.jdt.core.prefs).
  },

  markdown = {
    filetypes = { "markdown", "markdown.mdx", "md" },
    treesitter = { "markdown", "markdown_inline" },
    lsp = "marksman",
    formatter = "prettier",
  },

  latex = {
    filetypes = { "latex", "tex", "bib" },
    treesitter = "latex",
    lsp = "texlab",
    formatter = "tex-fmt",
  },

  c = {
    filetypes = { "c" },
    treesitter = "c",
    lsp = "clangd",
    formatter = "clang-format",
  },

  cpp = {
    filetypes = { "cpp", "hpp", "cc" },
    treesitter = "cpp",
    lsp = "clangd",
    formatter = "clang-format",
  },

  go = {
    filetypes = { "go" },
    treesitter = "go",
    lsp = "gopls",
    formatter = "gofumpt",
  },

  rust = {
    filetypes = { "rust" },
    treesitter = "rust",
    lsp = "rust_analyzer",
    formatter = "rustfmt",
    mason = { lsp = "rust-analyzer", formatter = false },
  },

  vim = {
    filetypes = { "vim", "vimdoc" },
    treesitter = { "vim", "vimdoc" },
  },

  bash = {
    filetypes = { "sh", "bash", "zsh" },
    treesitter = "bash",
    lsp = "bashls",
    mason = { lsp = "bash-language-server" },
    formatter = "shfmt",
    linter = "shellcheck",
    linter_enable = false,
  },

  make = {
    filetypes = { "make", "makefile" },
    treesitter = "make",
  },

  nu = {
    filetypes = { "nu" },
    treesitter = "nu",
    lsp = "nushell",
    formatter = "nufmt",
    mason = { lsp = false, formatter = false },
    -- install with: cargo install --git https://github.com/nushell/nufmt
    formatter_args = {
      "--config",
      vim.fn.expand("~/.config/nushell/nufmt.nuon"),
    },
  },

  json = {
    filetypes = { "json", "jsonc" },
    treesitter = "json",
    lsp = "jsonls",
    mason = { lsp = "json-lsp" },
    formatter = "prettier",
  },

  yaml = {
    filetypes = { "yml", "yaml" },
    treesitter = "yaml",
    lsp = "yamlls",
    mason = { lsp = "yaml-language-server" },
    formatter = "prettier",
    linter = "yamllint",
  },

  toml = {
    filetypes = { "toml", "tml" },
    treesitter = "toml",
    lsp = "tombi",
  },

  sql = {
    filetypes = { "sql" },
    treesitter = "sql",
    lsp = "sqlls",
    formatter = "sqlfmt",
    linter = "sqruff",
    linter_args = { "--exclude-rules", "LT105" },
  },

  just = {
    filetypes = { "just" },
    treesitter = "just",
    lsp = "just-lsp",
  },

  nix = {
    filetypes = { "nix" },
    treesitter = "nix",
    lsp = "nil_ls",
    mason = { lsp = "nil" },
    formatter = "alejandra",
  },

  assembly = {
    filetypes = { "gas", "asm", "nasm" },
    treesitter = "asm",
    lsp = "asm_lsp",
    formatter = "asmfmt",
  },

  backus_naur = {
    filetype = "bnf",
    treesitter = "ebnf",
  },
}

return {
  {
    "lang-system",
    dir = vim.fn.stdpath("config") .. "/lua/lang-system", -- local plugin
    name = "lang-system",
    main = "lang-system",
    lazy = false,
    priority = 100, -- load before Mason/lspconfig
    config = function(_, opts)
      lang_system.setup(opts)
    end,
    opts = {
      languages = languages,
    },
    keys = {
      { "<leader>dm", "<cmd>Mason<cr>", desc = "Mason UI" },
      { "<leader>dl", "<cmd>LanguageInstall<cr>", desc = "Install Language Tools" },
    },
  },

  {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = { "lang-system" }, -- ensure lang-system loads first
    config = function()
      lang_system.setup_mason()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false, -- main branch does not support lazy-loading
    build = ":TSUpdate",
    dependencies = {
      "lang-system",
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" }, -- textobject motions
    },
    config = function()
      lang_system.setup_treesitter()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "lang-system",
      "williamboman/mason-lspconfig.nvim", -- Mason <-> lspconfig bridge
    },
    config = function()
      lang_system.setup_lspconfig()
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = false, -- guarantees :Format and format_on_save for scripted `nvim +w` too
    dependencies = { "lang-system" },
    config = function()
      lang_system.setup_conform()
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "lang-system" },
    config = function()
      lang_system.setup_nvimlint()
    end,
  },
}
