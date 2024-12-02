return {
  {
    "marcos-venicius/tms.nvim",
    name = "tms",
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require("tms").setup({
        "gruvbox",
        "onedark",
        "rose-pine-main",
        "tokyonight-night",
        "catppuccin-frappe"
      })
    end
  }
}
