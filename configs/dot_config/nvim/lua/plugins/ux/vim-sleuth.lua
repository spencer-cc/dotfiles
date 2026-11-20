--- vim-sleuth: auto-detect indentation style from file contents

return {
  "tpope/vim-sleuth",
  event = "BufReadPost", -- detect after buffer is read
  enabled = false,
}
