return {
  {
    'sainnhe/everforest',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_background = 'hard'
      vim.cmd.colorscheme('everforest')
    end
  },
  --[[ {
    'sainnhe/gruvbox-material'
  },
  {
    'webhooked/kanso.nvim'
  },
  {
    'helbing/aura.nvim'
  },
  {
    "fynnfluegge/monet.nvim",
    name = "monet",
  },
  {
    "marcos-venicius/tms.nvim",
    name = "tms",
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function ()
      require("tms").setup({
        "everforest",
        -- "gruvbox-material",
        -- "kanso-ink",
        -- "aura",
        -- "monet"
      })
    end
  } ]]
}
