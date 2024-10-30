vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = "*.env.*",
  command = "set ft=sh"
})
