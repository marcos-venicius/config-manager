return {
  {
    'marcos-venicius/zenburned',
    config = function()
      vim.api.nvim_cmd({
        cmd = 'colorscheme',
        args = { 'zenburned' }
      }, {})
    end
  }
}
