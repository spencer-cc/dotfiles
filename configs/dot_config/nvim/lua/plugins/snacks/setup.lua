--- Snacks setup: toggle mappings, debug helpers, help/man window in floating split
--- vim.g.autoformat_enabled is the cross-module toggle for format-on-save (see core/autocmds)

local wrap_options = require("helpers.utils").wrap_options

return {
  "folke/snacks.nvim",
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- debug helpers
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end

        if vim.fn.has("nvim-0.11") == 1 then
          vim._print = function(_, ...)
            dd(...)
          end
        else
          vim.print = _G.dd
        end

        -- ---------- BINARY / EMPTY FILE PREVIEW + OPEN ----------
        -- Mirror nushell's xxd wrapper (shell-helpers.nu) for snacks previews and confirm.
        --   empty files  -> silent empty preview (no notify, no JSON item dump)
        --   binary files -> xxd in terminal buffer (ANSI colors via -R always)
        --   normal files -> original Snacks.picker.preview.file behavior
        -- Overrides apply to every picker that uses the default preview/jump (explorer,
        -- files, recent, git_files, lsp, etc.) since we mutate the module-level slots.

        --- Compute xxd column count matching nushell's formula:
        ---   num_chunks = min(32, floor((win_width - 21) / 4))
        ---   reserved = 10 (offset col) + 11 (ascii col + separators)
        ---   chunkbytes = 1, so each byte = (1*3)+1 = 4 visual chars
        ---@param win number window handle to size for
        ---@return string[] xxd args (without path)
        local function xxd_args(win)
          local max_cols, chunkbytes, reserved = 32, 1, 21
          local wincols = vim.api.nvim_win_get_width(win)
          local num_chunks = math.max(1, math.min(max_cols, math.floor((wincols - reserved) / ((chunkbytes * 3) + 1))))
          return {
            "-autoskip",
            "-u",
            "-R",
            "always",
            "-groupsize",
            tostring(chunkbytes),
            "-cols",
            tostring(num_chunks),
          }
        end

        --- Detect binary files by scanning first 1024 bytes for control chars
        --- (same pattern as snacks' own check at preview.lua:162)
        ---@param path string
        ---@return boolean
        local function is_binary_file(path)
          local fd = io.open(path, "rb")
          if not fd then
            return false
          end
          local head = fd:read(1024) or ""
          fd:close()
          return head:find("[%z\1-\8\11\12\14-\31]") ~= nil
        end

        --- Preview byte limit: 100 lines × 32 cols max = 3200 bytes
        ---@param stat_size number actual file size
        ---@return integer
        local function xxd_preview_bytes(stat_size)
          return math.min(stat_size, 1000 * 32)
        end

        -- 1) Preview override: empty -> silent, binary -> xxd (limited), else original
        local orig_preview_file = Snacks.picker.preview.file
        Snacks.picker.preview.file = function(ctx)
          local path = Snacks.picker.util.path(ctx.item)
          if not path then
            return orig_preview_file(ctx)
          end

          local stat = vim.uv.fs_stat(path)
          if not stat or stat.type ~= "file" then
            return orig_preview_file(ctx)
          end

          -- Preserve snacks' large-file guard (1MB default)
          local max_size = ctx.picker.opts.previewers.file.max_size or (1024 * 1024)
          if stat.size > max_size then
            return orig_preview_file(ctx)
          end

          -- Empty file: silent empty preview, no notify, no JSON dump
          if stat.size == 0 then
            ctx.preview:reset()
            ctx.preview:set_title(ctx.item.preview_title or ctx.item.title or vim.fn.fnamemodify(path, ":t"))
            ctx.preview:set_lines({})
            return
          end

          -- Image file: delegate to snacks' built-in image previewer (snacks.image)
          -- Must check BEFORE the binary branch, since image files contain control
          -- bytes and would otherwise be classified as binary -> xxd dump.
          -- Mirrors snacks' own ordering at preview.lua:118-120.
          if Snacks.image.supports_file(path) and Snacks.image.config.enabled ~= false then
            return orig_preview_file(ctx)
          end

          -- Binary file: xxd in terminal buffer (ft=nil => term=true => ANSI colors render)
          -- NOTE: M.cmd passes cmd to jobstart, which expects cmd[1] to be the executable.
          if is_binary_file(path) then
            local cmd = vim.list_extend({ "xxd", "-l", tostring(xxd_preview_bytes(stat.size)) }, xxd_args(ctx.win))
            table.insert(cmd, path)
            return Snacks.picker.preview.cmd(cmd, ctx, { ft = nil })
          end

          -- Normal file: original behavior
          return orig_preview_file(ctx)
        end

        -- 2) Confirm override: binary files open in read-only xxd terminal buffer
        --    (no -l limit, full hex dump) in the current window
        local orig_jump = Snacks.picker.actions.jump
        Snacks.picker.actions.jump = function(picker, item, action)
          local path = item and Snacks.picker.util.path(item)
          -- Skip xxd for image files: let the original jump handle them.
          -- Image files are binary (control bytes) but should not open as hex.
          local is_image = Snacks.image.supports_file(path) and Snacks.image.config.enabled ~= false
          if path and is_binary_file(path) and not is_image then
            picker:close()
            vim.schedule(function()
              -- :terminal opens in current window, replacing the buffer
              local win = vim.api.nvim_get_current_win()
              local args = xxd_args(win)
              local escaped = vim.tbl_map(vim.fn.shellescape, args)
              table.insert(escaped, vim.fn.shellescape(path))
              vim.cmd("terminal xxd " .. table.concat(escaped, " "))
            end)
            return
          end
          return orig_jump(picker, item, action)
        end

        -- UI toggles (<leader>u prefix)
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.option("colorcolumn", { name = "Color Column", off = "", on = "80" }):map("<leader>uv")

        -- readonly/modifiable toggle (safety lock; won't override natively read-only buffers)
        Snacks.toggle
          .new({
            name = "Readonly",
            get = function()
              return vim.b.modifiable_locked == true
            end,
            set = function(state)
              if vim.bo.readonly then
                Snacks.notify.error("Can't toggle read-only", { title = "Readonly" })
                return
              end
              if state then
                vim.bo.modifiable = false
                vim.b.modifiable_locked = true
                Snacks.notify("Enabled **Readonly**", { title = "Readonly", level = vim.log.levels.INFO })
              else
                vim.bo.modifiable = true
                vim.b.modifiable_locked = false
                Snacks.notify("Disabled **Readonly**", { title = "Readonly", level = vim.log.levels.WARN })
              end
            end,
            notify = false, -- custom notifications in set() for edge-case messages
          })
          :map("<leader>uR")

        -- git signs toggle
        Snacks.toggle
          .new({
            name = "Git Signs",
            get = function()
              return require("gitsigns.config").config.signcolumn
            end,
            set = function(state)
              require("gitsigns").toggle_signs(state)
            end,
          })
          :map("<leader>uG")

        -- format-on-save toggle (reads vim.g.autoformat_enabled from core/autocmds)
        Snacks.toggle
          .new({
            name = "Auto Format",
            get = function()
              return vim.g.autoformat_enabled ~= false
            end,
            set = function(state)
              vim.g.autoformat_enabled = state
            end,
          })
          :map("<leader>uf")

        -- inline image toggle
        Snacks.toggle
          .new({
            name = "Inline Images",
            get = function()
              return Snacks.image.config.doc.inline
            end,
            set = function(state)
              Snacks.image.config.doc.inline = state
              local langs = Snacks.image.langs()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                  local ft = vim.bo[buf].filetype
                  if vim.tbl_contains(langs, ft) then
                    Snacks.image.placement.clean(buf)
                    pcall(vim.api.nvim_del_augroup_by_name, "snacks.image.inline." .. buf)
                    vim.b[buf].snacks_image_attached = nil
                    if state then
                      Snacks.image.doc.attach(buf)
                    end
                  end
                end
              end
            end,
          })
          :map("<leader>ui")

        -- colorizer toggle
        Snacks.toggle
          .new({
            name = "Colorizer",
            get = function()
              return vim.b.colorizer_enabled ~= false
            end,
            set = function(state)
              vim.b.colorizer_enabled = state
              if state then
                require("colorizer").attach_to_buffer(0)
              else
                require("colorizer").detach_from_buffer(0)
              end
            end,
          })
          :map("<leader>uc")
      end,
    })

    -- open :help and :Man in a floating window instead of a split
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = { "*.txt", "man://*" },
      callback = function()
        if vim.bo.filetype == "help" or vim.bo.filetype == "man" then
          local win = vim.api.nvim_get_current_win()
          local cfg = vim.api.nvim_win_get_config(win)
          if cfg.relative == "" then -- not already floating
            local buf = vim.api.nvim_get_current_buf()
            local ft = vim.bo.filetype
            if ft == "man" then
              -- man.lua sets bufhidden='unload': closing the only window would
              -- wipe the page before the float opens (help buffers use 'hide')
              vim.bo[buf].bufhidden = "hide"
            end
            vim.api.nvim_win_close(win, false)
            Snacks.win({
              buf = buf,
              border = "rounded",
              title = ft == "man" and " Man " or " Help ",
              width = 0.9,
              height = 0.8,
              wo = vim.tbl_extend("force", wrap_options, {
                signcolumn = "yes",
                statuscolumn = " ",
                conceallevel = 3,
              }),
            })
          end
        end
      end,
    })
  end,
}
