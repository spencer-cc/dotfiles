--- Language System Wiring
---
--- Consumes the per-language toolchain table defined in
--- lua/plugins/lang-system.lua and wires Mason, treesitter, LSP, conform
--- (formatters), and nvim-lint (linters). Also provides :LanguageInstall.

local M = {
  languages = {},
}

function M.setup(opts)
  M.languages = (opts and opts.languages) or {}
end

---- Install command -----------------------------------------------------------

--- Mason package name for a tool: explicit override, false (not Mason-managed),
--- or the tool name with underscores converted to dashes.
--- @param kind string "lsp" | "formatter" | "linter"
--- @param name string Tool name (lspconfig server or executable name)
--- @param lang table Language definition
--- @return string|boolean Mason package name, or false when not Mason-managed
local function mason_name(kind, name, lang)
  local override = lang.mason and lang.mason[kind]
  if override ~= nil then
    return override
  end
  return name:gsub("_", "-")
end

local function mason_install(pkg_name)
  local registry = require("mason-registry")
  local ok, pkg = pcall(registry.get_package, pkg_name)
  if ok and not pkg:is_installed() and not pkg:is_installing() then
    pkg:install()
    return true
  end
  return false
end

local function is_treesitter_installed(parser_name)
  local ok, _ = pcall(vim.treesitter.language.inspect, parser_name)
  return ok
end

local function get_parsers(lang)
  if not lang.treesitter then
    return {}
  end
  if type(lang.treesitter) == "table" then
    return lang.treesitter
  end
  return { lang.treesitter }
end

--- Mason-install a language's tools (skipping non-Mason and disabled ones)
--- and treesitter-install its parsers.
--- @param name string Language key in M.languages
function M.install(name)
  local lang = M.languages[name]
  if not lang then
    vim.notify("Unknown language: " .. name, vim.log.levels.ERROR)
    return
  end

  local installed = {}

  for _, kind in ipairs({ "lsp", "formatter", "linter" }) do
    local tool = lang[kind]
    if tool and lang[kind .. "_enable"] ~= false then
      local pkg = mason_name(kind, tool, lang)
      if pkg ~= false and mason_install(pkg) then
        installed[#installed + 1] = pkg
      end
    end
  end

  for _, parser in ipairs(get_parsers(lang)) do
    if not is_treesitter_installed(parser) then
      require("nvim-treesitter").install({ parser })
      installed[#installed + 1] = "treesitter:" .. parser
    end
  end

  local message
  if #installed > 0 then
    message = string.format("Language '%s' installed: %s", name, table.concat(installed, ", "))
  else
    message = string.format("Language '%s' - all tools already installed", name)
  end
  vim.notify(message, vim.log.levels.INFO)
end

---- Setup functions (called from the plugin specs) -----------------------------

function M.setup_mason()
  require("mason").setup({
    ui = {
      border = "rounded",
    },
  })
end

function M.setup_treesitter()
  -- textobjects configuration (nvim-treesitter-textobjects main branch API)
  require("nvim-treesitter-textobjects").setup({
    move = {
      set_jumps = true, -- jump list entries for function motions
    },
  })

  local ts_move = require("nvim-treesitter-textobjects.move")
  local map = require("helpers.keys").map
  map({ "n", "x", "o" }, "]m", function()
    ts_move.goto_next_start("@function.outer", "textobjects")
  end, "Next function start")
  map({ "n", "x", "o" }, "]M", function()
    ts_move.goto_next_end("@function.outer", "textobjects")
  end, "Next function end")
  map({ "n", "x", "o" }, "[m", function()
    ts_move.goto_previous_start("@function.outer", "textobjects")
  end, "Previous function start")
  map({ "n", "x", "o" }, "[M", function()
    ts_move.goto_previous_end("@function.outer", "textobjects")
  end, "Previous function end")

  -- Start treesitter highlighting + indentation per buffer (main branch API).
  -- Highlighting and indentexpr are core/plugin features that must be
  -- enabled per filetype; no parser/query installed -> pcall fails silently.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
      -- treesitter indentation is experimental; python ships a better ftplugin
      if args.match ~= "python" then
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })
end

function M.setup_lspconfig()
  local globals = require("helpers.globals")

  vim.diagnostic.config({
    virtual_text = false,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = globals.lsp_icons.error,
        [vim.diagnostic.severity.WARN] = globals.lsp_icons.warn,
        [vim.diagnostic.severity.INFO] = globals.lsp_icons.info,
        [vim.diagnostic.severity.HINT] = globals.lsp_icons.hint,
      },
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
      max_width = 80, -- keep diagnostic popups narrow; long lines wrap
    },
  })

  local on_attach = function(client, bufnr)
    local lsp_map = require("helpers.keys").lsp_map

    -- conform owns formatting when the language defines a formatter
    local ft = vim.bo[bufnr].filetype
    for _, lang in pairs(M.languages) do
      if
        lang.filetypes
        and vim.tbl_contains(lang.filetypes, ft)
        and lang.formatter
        and lang.formatter_enable ~= false
      then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end
    end

    lsp_map("J", vim.diagnostic.open_float, bufnr, "LSP Diagnostics")
    lsp_map("K", vim.lsp.buf.hover, bufnr, "LSP Hover")
    -- all other LSP actions live in the H action picker (lang-system/lsp_actions.lua)

    lsp_map("<leader>ff", "<cmd>Format<cr>", bufnr, "Format")
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

  local tool_names = {} -- formatter/linter names to exclude from auto-enabling

  for _, lang in pairs(M.languages) do
    if lang.lsp and lang.lsp_enable ~= false then
      local config = vim.tbl_deep_extend("force", {
        on_attach = on_attach,
        capabilities = capabilities,
      }, lang.config or {})
      vim.lsp.config(lang.lsp, config)
      -- servers managed outside Mason are never seen by mason-lspconfig's
      -- automatic_enable and must be enabled explicitly
      if lang.mason and lang.mason.lsp == false then
        vim.lsp.enable(lang.lsp)
      end
    end
    for _, kind in ipairs({ "formatter", "linter" }) do
      if lang[kind] then
        tool_names[#tool_names + 1] = lang[kind]
      end
    end
  end

  -- Exclude formatter/linter tool names from automatic enabling:
  -- some (e.g. stylua, which ships an --lsp mode) have Mason package specs
  -- declaring an lspconfig name, and would otherwise attach as LSP servers
  -- alongside conform.
  require("mason-lspconfig").setup({
    automatic_enable = { exclude = tool_names },
  })
end

function M.setup_conform()
  local conform = require("conform")

  -- formatters_by_ft: filetype -> formatter names, derived from language defs.
  local formatters_by_ft = {}
  local formatter_opts = {} -- per-tool conform formatter config (extra args)

  for _, lang in pairs(M.languages) do
    if lang.formatter and lang.formatter_enable ~= false then
      for _, ft in ipairs(lang.filetypes or {}) do
        local list = formatters_by_ft[ft] or {}
        if not vim.tbl_contains(list, lang.formatter) then
          table.insert(list, lang.formatter)
        end
        formatters_by_ft[ft] = list
      end
      if lang.formatter_args then
        formatter_opts[lang.formatter] = { append_args = lang.formatter_args }
      end
    end
  end

  conform.setup({
    formatters_by_ft = formatters_by_ft,
    formatters = formatter_opts,
    -- respects vim.g.autoformat_enabled (toggled via :AutoFormatToggle / <leader>uf)
    format_on_save = function(bufnr)
      if vim.g.autoformat_enabled == false then
        return
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,
  })

  vim.api.nvim_create_user_command("Format", function()
    conform.format({ lsp_format = "fallback", async = false })
  end, { desc = "Format buffer (conform with LSP fallback)" })
end

function M.setup_nvimlint()
  local lint = require("lint")

  local linters_by_ft = {}
  for _, lang in pairs(M.languages) do
    if lang.linter and lang.linter_enable ~= false then
      for _, ft in ipairs(lang.filetypes or {}) do
        local list = linters_by_ft[ft] or {}
        if not vim.tbl_contains(list, lang.linter) then
          table.insert(list, lang.linter)
        end
        linters_by_ft[ft] = list
      end
      if lang.linter_args and lint.linters[lang.linter] then
        local linter_def = lint.linters[lang.linter]
        linter_def.args = vim.list_extend(vim.deepcopy(linter_def.args or {}), lang.linter_args)
      end
    end
  end
  lint.linters_by_ft = linters_by_ft

  lint.try_lint()

  vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })
end

---- Commands -------------------------------------------------------------------

vim.api.nvim_create_user_command("AutoFormatToggle", function()
  vim.g.autoformat_enabled = not vim.g.autoformat_enabled
  vim.notify(
    string.format("Auto-formatting %s", vim.g.autoformat_enabled and "enabled" or "disabled"),
    vim.log.levels.INFO
  )
end, { desc = "Toggle auto-formatting on save" })

vim.api.nvim_create_user_command("LanguageInstall", function(opts)
  local name = opts.args
  if name == "" then
    local names = vim.tbl_keys(M.languages)
    table.sort(names)
    vim.ui.select(names, {
      prompt = "Install language:",
    }, function(choice)
      if choice then
        M.install(choice)
      end
    end)
  else
    M.install(name)
  end
end, {
  nargs = "?",
  complete = function()
    local names = vim.tbl_keys(M.languages)
    table.sort(names)
    return names
  end,
  desc = "Install a language's Mason packages and treesitter parsers",
})

return M
