--- LSP action picker: menu of LSP actions for the current buffer/symbol.
--- Availability is derived from the attached servers' capabilities
--- (union across clients); unavailable entries are dimmed and won't run.
--- This is the single access point for LSP actions (no <leader>l binds).

local M = {}

-- capability values can be: true, a table (e.g. { prepareProvider = true }), false/nil
---@param caps table
---@param name string?
---@return boolean
local function cap_supported(caps, name)
  if name == nil then
    return true -- always-available entries (e.g. diagnostics pickers)
  end
  local v = caps[name]
  if type(v) == "table" then
    return next(v) ~= nil
  end
  return v == true
end

--- Union of capabilities supported by any client attached to the current buffer
---@return table<string, boolean>
local function buf_capabilities()
  local caps = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    for name, v in pairs(client.server_capabilities) do
      if cap_supported({ [name] = v }, name) then
        caps[name] = true
      end
    end
  end
  return caps
end

--- Action catalog: kind icon (from helpers.lsp_kinds — same glyphs as the
--- blink.cmp completion menu), label, theme group (colors the icon),
--- required capability (nil = always available), short description, run
--- function. Snacks is resolved at open() time (snacks is lazy = false,
--- always loaded, but resolving lazily keeps require order irrelevant).
---@return { icon: string, label: string, group: string, cap: string?, desc: string, run: fun() }[]
local function catalog()
  local S = Snacks.picker
  local K = require("helpers.lsp_kinds")
  return {
    {
      icon = K.Snippet,
      label = "Code Action",
      group = "edit",
      cap = "codeActionProvider",
      desc = "apply quickfix / refactor here",
      run = vim.lsp.buf.code_action,
    },
    {
      icon = K.Variable,
      label = "Rename Symbol",
      group = "edit",
      cap = "renameProvider",
      desc = "rename across project",
      run = vim.lsp.buf.rename,
    },
    {
      icon = K.Method,
      label = "Signature Help",
      group = "info",
      cap = "signatureHelpProvider",
      desc = "show parameter hints",
      run = vim.lsp.buf.signature_help,
    },
    {
      icon = K.Text,
      label = "Hover",
      group = "info",
      cap = "hoverProvider",
      desc = "show docs for symbol",
      run = vim.lsp.buf.hover,
    },
    {
      icon = K.Function,
      label = "Definition",
      group = "jump",
      cap = "definitionProvider",
      desc = "jump to where defined",
      run = S.lsp_definitions,
    },
    {
      icon = K.TypeParameter,
      label = "Declaration",
      group = "jump",
      cap = "declarationProvider",
      desc = "jump to declaration",
      run = S.lsp_declarations,
    },
    {
      icon = K.Class,
      label = "Type Definition",
      group = "jump",
      cap = "typeDefinitionProvider",
      desc = "jump to type definition",
      run = S.lsp_type_definitions,
    },
    {
      icon = K.Interface,
      label = "Implementation",
      group = "find",
      cap = "implementationProvider",
      desc = "list implementations",
      run = S.lsp_implementations,
    },
    {
      icon = K.Reference,
      label = "References",
      group = "find",
      cap = "referencesProvider",
      desc = "list all usages",
      run = S.lsp_references,
    },
    {
      icon = K.Enum,
      label = "Buffer Symbols",
      group = "find",
      cap = "documentSymbolProvider",
      desc = "outline of this file",
      run = S.lsp_symbols,
    },
    {
      icon = K.Module,
      label = "Workspace Symbols",
      group = "find",
      cap = "workspaceSymbolProvider",
      desc = "search project symbols",
      run = S.lsp_workspace_symbols,
    },
    {
      icon = K.Event,
      label = "Incoming Calls",
      group = "calls",
      cap = "callHierarchyProvider",
      desc = "who calls this",
      run = S.lsp_incoming_calls,
    },
    {
      icon = K.Operator,
      label = "Outgoing Calls",
      group = "calls",
      cap = "callHierarchyProvider",
      desc = "what this calls",
      run = S.lsp_outgoing_calls,
    },
    {
      icon = K.File,
      label = "Buffer Diagnostics",
      group = "diag",
      cap = nil,
      desc = "problems in this file",
      run = S.diagnostics_buffer,
    },
    {
      icon = K.Folder,
      label = "All Diagnostics",
      group = "diag",
      cap = nil,
      desc = "problems in project",
      run = S.diagnostics,
    },
  }
end

--- Highlight group per theme group; fg sourced from the chezmoi-generated
--- palette (same tokens lualine uses). Defined at open() time so they always
--- track the active colorscheme.
---@return table<string, string> group -> highlight group name
local function ensure_group_hls()
  local palette = require("colorscheme.palette")
  local group_fg = {
    edit = palette.syntax.keyword,
    info = palette.diagnostic.info,
    jump = palette.syntax.function_name,
    find = palette.syntax.type,
    calls = palette.syntax.property,
    diag = palette.diagnostic.error,
  }
  local names = {}
  for group, fg in pairs(group_fg) do
    local name = "LspActions" .. group:sub(1, 1):upper() .. group:sub(2)
    vim.api.nvim_set_hl(0, name, { fg = fg })
    names[group] = name
  end
  return names
end

---@param item table? selected picker item
---@param picker snacks.Picker
local function confirm(picker, item)
  if not item or not item.run then
    return
  end
  if not item.available then
    Snacks.notify.warn(("**%s** not supported by attached LSP servers"):format(item.label), { title = "LSP Actions" })
    return
  end
  picker:norm(function()
    picker:close()
    item.run()
  end)
end

--- Open the LSP action picker for the current buffer
function M.open()
  local caps = buf_capabilities()
  local group_hls = ensure_group_hls()

  local items = {} ---@type table[]
  local available, unavailable = {}, {}
  for _, action in ipairs(catalog()) do
    local item = {
      text = action.label,
      icon = action.icon,
      label = action.label,
      icon_hl = group_hls[action.group],
      desc = action.desc,
      run = action.run,
      available = cap_supported(caps, action.cap),
    }
    table.insert(item.available and available or unavailable, item)
  end
  -- available actions first, unavailable (capability info) after
  vim.list_extend(items, available)
  vim.list_extend(items, unavailable)

  Snacks.picker.pick({
    title = "LSP Actions",
    items = items,
    format = function(item, _)
      -- dimmed entries override the group-colored icon
      local label_hl = item.available and "Normal" or "Comment"
      local icon_hl = item.available and item.icon_hl or "Comment"
      local ret = {}
      -- fixed-width icon column keeps labels aligned
      ret[#ret + 1] = { Snacks.picker.util.align(item.icon, 2) .. " ", icon_hl }
      ret[#ret + 1] = { item.label, label_hl }
      -- right-aligned description, pinned to the window edge
      ret[#ret + 1] = {
        col = 0,
        virt_text = { { item.desc, item.available and "SnacksPickerDesc" or "Comment" } },
        virt_text_pos = "right_align",
        hl_mode = "combine",
      }
      return ret
    end,
    confirm = confirm,
    layout = { preset = "select" }, -- compact menu, no preview
  })
end

return M
