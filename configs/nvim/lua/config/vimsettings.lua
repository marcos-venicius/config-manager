local opt = vim.opt

opt.wildignore:append { "*.pyc", "node_modules/**", ".git/**" }
opt.signcolumn = "yes"
opt.expandtab = true
opt.wildmenu = true
opt.hlsearch = true
opt.ruler = true
opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
opt.autoindent = true
opt.wrap = false
opt.smartcase = true
opt.ignorecase = true
opt.hidden = true
opt.splitbelow = true
opt.splitright = true
opt.cursorline = false
opt.smarttab = true
opt.incsearch = true
opt.lazyredraw = true
opt.magic = true
opt.showmatch = true
opt.fileformat = "unix"

vim.g.editorconfig = true

local augroup = vim.api.nvim_create_augroup("CStyleIndent", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { "*.c", "*.h", "*.cs" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_cmd({
	cmd = 'colorscheme',
	args = { 'default' }
}, {})

vim.keymap.set('n', '<space><space>', ':nohlsearch<cr>')
