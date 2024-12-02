vim.wo.signcolumn='yes'
vim.o.expandtab=true
vim.o.wildmenu=true
vim.o.hlsearch=true
vim.o.ruler=true
vim.o.nu=true
vim.o.rnu=true
vim.o.tabstop=2
vim.o.shiftwidth=2
vim.o.softtabstop=2
vim.o.smartindent=true
vim.o.autoindent=true
vim.o.wrap=false
vim.o.smartcase=true
vim.o.ignorecase=true
vim.o.hidden=true
vim.o.splitbelow=true
vim.o.splitright=true
vim.o.cursorline=true
vim.o.smarttab=true
vim.o.incsearch=true
vim.o.lazyredraw=true
vim.o.magic=true
vim.o.showmatch=true
vim.opt.background='dark'
vim.g.editorconfig = true
vim.opt.fileformat = 'unix'

vim.api.nvim_create_autocmd('BufRead', {
  pattern = '*.c',
  command = 'set tabstop=4 shiftwidth=4 softtabstop=4 expandtab'
})

vim.api.nvim_create_autocmd('BufNewFile', {
  pattern = '*.c',
  command = 'set tabstop=4 shiftwidth=4 softtabstop=4 expandtab'
})
