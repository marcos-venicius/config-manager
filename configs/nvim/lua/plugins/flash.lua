return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    config = function ()
      require("flash").setup({
        modes = {
          char = {
            enabled = false, -- Disables flash for f, t, F, T
          },
        },
      })
    end,
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  }
}
