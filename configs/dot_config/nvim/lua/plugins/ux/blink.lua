--- blink.cmp: completion with LSP, snippets, buffer, and path sources

-- prebuilt fuzzy binary from the pinned release; must load before LSP attaches
-- so its capabilities are registered with every client

local kind_icons = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰜢",
  Variable = "󰀫",
  Class = "󰠲",
  Interface = "󰰃",
  Module = "󰏓",
  Property = "󰜷",
  Unit = "󰑭",
  Value = "󰎠",
  Enum = "󰉻",
  Keyword = "󰌋",
  Snippet = "󰘍",
  Color = "󰏘",
  File = "󰈔",
  Reference = "󰈇",
  Folder = "󰉋",
  EnumMember = "",
  Constant = "󰏿",
  Struct = "󰙅",
  Event = "󱐋",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

return {
  "saghen/blink.cmp",
  version = "1.*",
  lazy = false,
  priority = 995, -- before lang-system (100) / lspconfig; after colorscheme (1000)
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = {
      preset = "none",
      -- menu navigation
      ["<Down>"] = { "select_next", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "scroll_documentation_down", "select_next", "fallback" },
      ["<C-k>"] = { "scroll_documentation_up", "select_prev", "fallback" },
      -- pure docs scrolling (no selection fallback)
      ["<C-Down>"] = { "scroll_documentation_down", "fallback" },
      ["<C-Up>"] = { "scroll_documentation_up", "fallback" },
      -- accept
      ["<CR>"] = { "accept", "fallback" },
      -- snippet placeholder jumping
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      -- trigger
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    },
    appearance = { kind_icons = kind_icons },
    completion = {
      list = {
        -- no preselect: CR only confirms an explicitly selected item,
        -- otherwise falls back to inserting a newline (old cmp select=false)
        selection = { preselect = false, auto_insert = false },
      },
      menu = {
        border = "rounded",
        winhighlight = "Normal:CmpPmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
        draw = { columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } } },
      },
      documentation = {
        auto_show = true,
        window = { border = "rounded" },
      },
    },
    sources = {
      default = { "lsp", "snippets", "buffer", "path" },
      providers = {
        path = { opts = { show_hidden_files_by_default = true } },
      },
    },
  },
}
