return {
  {
    'wesgibbs/vim-irblack',
    config = function()
      vim.api.nvim_cmd({
        cmd = 'colorscheme',
        args = { 'ir_black' }
      }, {})
    end
  }
}
