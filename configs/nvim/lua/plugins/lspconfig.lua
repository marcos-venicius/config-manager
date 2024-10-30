return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

      'folke/neodev.nvim',
    },
    config = function()
      require("config.lspconfig")
    end
  },
}

