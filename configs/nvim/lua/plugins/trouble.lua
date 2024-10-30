return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      {
        "<leader>d",
        "<cmd>Trouble custom_diagnostics toggle focus=true<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>s",
        "<cmd>Trouble lsp_document_symbols toggle focus=true win.position=right<cr>",
        desc = "Symbols (Trouble)",
      },
    },
    config = function()
      require('trouble').setup {
        modes = {
          custom_diagnostics = {
            mode = "diagnostics",
            preview = {
              type = "split",
              relative = "win",
              position = "right",
              size = 0.3,
            },
          },
        },
      }
    end
  }
}
