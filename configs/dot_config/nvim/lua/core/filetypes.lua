-- explicit mappings for dotfiles whose extension doesn't match their syntax
local dot_mappings = {
  ["zshrc"] = "zsh",
  ["bashrc"] = "bash",
  ["vimrc"] = "vim",
  ["screenrc"] = "screen",
  ["gitconfig"] = "toml",
}

-- user-local extension → filetype mappings
local extension_mappings = {
  ["bnf"] = "ebnf",
}

vim.filetype.add({
  pattern = {
    -- strip a trailing '.tmpl'
    [".*/(.+)%.tmpl$"] = function(path, bufnr)
      local stripped = path:match("(.+)%.tmpl$")
      return vim.filetype.match({ filename = stripped, buf = bufnr })
    end,
    -- map '.foo' files (e.g. .zshrc → zsh)
    [".*/%.([%w_-]+)$"] = function(_, _, name)
      return dot_mappings[name] or name
    end,
    -- map chezmoi source names with attribute prefixes
    [".*/[a-z_]*dot_([%w_-]+)$"] = function(_, _, name)
      return dot_mappings[name] or name
    end,
  },
  extension = vim.tbl_extend("force", {
    tex = "tex",
    bib = "tex",
    aux = "tex",
  }, extension_mappings),
  filename = {
    --["foo"] = "bar"
  },
})

vim.treesitter.language.register("asm", { "gas", "asm", "nasm" })
