--- Snacks picker: fuzzy finder source configs (browsing, LSP, git, explorer)
--- hidden_search_options: DRY table for pickers that don't need a search input

local wrap_options = require("helpers.utils").wrap_options

-- pickers that only browse/select (no text search needed)
local hidden_search_options = {
  layout = { hidden = { "input" } },
  auto_confirm = false,
}

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        buffers = {
          format = "file", -- icon + path:line (no buf nr/flags)
          layout = { hidden = { "input" } }, -- browse-only
          win = {
            list = {
              keys = {
                ["l"] = "confirm", -- enter buffer with l
              },
            },
          },
        },
        notifications = {
          layout = { hidden = { "input" } },
          win = {
            preview = {
              wo = wrap_options, -- wrap long notification text
            },
          },
        },
        todo_comments = {
          layout = { hidden = { "input" } },
        },
        marks = {
          layout = { hidden = { "input" } },
        },
        keymaps = {
          -- custom confirm: jump to keymap definition file
          confirm = function(picker, item)
            picker:norm(function()
              if item then
                picker:close()
                if item.file and item.pos then
                  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
                  vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
                elseif item.file then
                  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
                else
                  vim.notify("No file location available for this keymap", vim.log.levels.WARN)
                end
              end
            end)
          end,
        },
        undo = {
          layout = {
            hidden = { "input" },
            layout = { -- side-by-side layout for undo tree
              width = 0.9,
              height = 0.9,
              min_width = 100,
              min_height = 30,
              box = "horizontal",
              {
                box = "vertical",
                width = 42,
                { win = "input", height = 0 },
                { win = "list", height = 0 },
              },
              { win = "preview", width = 0 },
            },
          },
          win = {
            input = { border = "rounded" },
            list = { border = "rounded" },
            preview = { border = "rounded" },
          },
        },
        -- browse-only LSP pickers (no search input)
        lsp_definitions = hidden_search_options,
        lsp_declarations = hidden_search_options,
        lsp_references = hidden_search_options,
        lsp_implementations = hidden_search_options,
        lsp_type_definitions = hidden_search_options,
        lsp_incoming_calls = hidden_search_options,
        lsp_outgoing_calls = hidden_search_options,
        lsp_symbols = hidden_search_options,
        lsp_workspaces_symbols = hidden_search_options,
        -- browse-only diagnostic/git pickers
        diagnostics_buffer = hidden_search_options,
        diagnostics = hidden_search_options,
        git_log = hidden_search_options,
        git_files = hidden_search_options,
        git_branches = hidden_search_options,
        git_log_line = hidden_search_options,
        git_log_file = hidden_search_options,
        git_diff = hidden_search_options,
        explorer = {
          ignored = false,
          hidden = true,
          layout = {
            preset = "sidebar",
            preview = "main", -- preview in main window
          },
          win = {
            list = {
              keys = {
                ["p"] = "toggle_preview", -- both P and p toggle preview
              },
            },
            preview = {
              col = 0,
              row = 0,
              border = "rounded",
            },
          },
        },
      },
    },
  },
}
