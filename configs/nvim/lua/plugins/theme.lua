return {
  {
    'rainstf/zenburn-m',
    config = function()
      vim.api.nvim_cmd({
        cmd = 'colorscheme',
        args = { 'zenburn-m' }
      }, {})
    end
  }
}
