--- Core keymaps: editing, yank, navigation, disabled defaults
--- Uses helpers.keys.map for consistent silent+desc keymaps

local map = require("helpers.keys").map

---- Core Editing ----

map("n", "<esc>", "<cmd>nohlsearch<cr><esc>", "Esc + clear hl")
map("n", "U", "<C-r>", "Redo")

-- navigate by visual lines when wrapping is on
vim.keymap.set(
  { "n", "x" },
  "j",
  "v:count == 0 ? 'gj' : 'j'",
  { desc = "Down a visual line", expr = true, silent = true }
)
vim.keymap.set(
  { "n", "x" },
  "k",
  "v:count == 0 ? 'gk' : 'k'",
  { desc = "Up a visual line", expr = true, silent = true }
)
vim.keymap.set({ "n", "x" }, "0", "&wrap ? 'g0' : '0'", { desc = "Start of [visual] line", expr = true, silent = true })
vim.keymap.set(
  { "n", "x" },
  "^",
  "&wrap ? 'g^' : '^'",
  { desc = "First non-blank of [visual] line", expr = true, silent = true }
)
vim.keymap.set({ "n", "x" }, "$", "&wrap ? 'g$' : '$'", { desc = "End of [visual] line", expr = true, silent = true })

-- stay in visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

---- Yank & Register Operations ----
-- d/c use black-hole register to preserve clipboard contents
vim.keymap.set("n", "d", '"_d', {
  remap = false,
  silent = true,
  desc = "Delete without yanking",
})
vim.keymap.set("v", "d", '"_d', {
  remap = false,
  silent = true,
  desc = "Delete visual selection without yanking",
})

vim.keymap.set("n", "c", '"_c', {
  remap = false,
  silent = true,
  desc = "Change without yanking",
})
vim.keymap.set("v", "c", '"_c', {
  remap = false,
  silent = true,
  desc = "Change visual selection without yanking",
})

-- paste without overwriting register
map("x", "p", [["_dp]], "Paste without copying")
map("x", "P", [["_dp]], "Paste without copying")

-- cut line (yank + delete)
vim.keymap.set("n", "xx", "yydd", {
  remap = false,
  silent = true,
  desc = "Yank line then delete it",
})

---- Interface ----

map("n", "<leader>bd", function()
  Snacks.bufdelete.delete()
end, "Close")
map("n", "<leader>br", "<cmd>edit!<CR>", "Revert")
map("n", "<leader>ur", "<cmd>nohl<cr>", "Clear highlights")

---- File ----

map("n", "<leader>fp", function()
  vim.notify(vim.api.nvim_buf_get_name(0), vim.log.levels.INFO, { title = "File Path" })
end, "File Path")
map("n", "<leader>fP", function()
  local path = vim.api.nvim_buf_get_name(0)
  vim.notify(path, vim.log.levels.INFO, { title = "File Path" })
  vim.fn.setreg("+", path)
end, "File Path (yank)")

---- Command-line Mode (Emacs-style) ----

vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-e>", "<End>")
vim.keymap.set("c", "<M-b>", "<S-Left>")
vim.keymap.set("c", "<M-f>", "<S-Right>")
vim.keymap.set("c", "<M-BS>", "<C-w>")

---- LSP ----

-- action picker for the current buffer/symbol; doubles as capability info
-- in non-LSP buffers (unavailable actions shown dimmed)
map("n", "H", function()
  require("lang-system.lsp_actions").open()
end, "LSP Actions")

---- Disabled Keymaps ----

vim.keymap.set("n", "Q", "<Nop>") -- ex mode
vim.keymap.set("n", "gQ", "<Nop>")
vim.keymap.set("n", "q:", "<Nop>") -- command window
vim.keymap.set("n", "q/", "<Nop>")
vim.keymap.set("n", "q?", "<Nop>")
vim.keymap.set({ "n", "x" }, "J", "<Nop>") -- free for LSP diagnostics (buffer-local)

-- fold operations disabled (zz/zt/zb/zg/zw/zh/zl still work)
for _, key in ipairs(require("helpers.globals").disabled_fold_keys) do
  vim.keymap.set("n", key, "<Nop>")
end
