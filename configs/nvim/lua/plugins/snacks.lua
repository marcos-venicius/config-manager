return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
        max_width = 80,
        max_height = 40,
      },
    },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      enabled = false,
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = { notification = {} },
    gh = {},
  },
  keys = {
    { "<leader>ls", function() Snacks.picker.lsp_symbols() end, desc = "Document Symbols" },
    { "<leader>lS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace Symbols" },

    { "<leader>nn", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>nd", function() Snacks.notifier.hide() end, desc = "Dismiss All" },

    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Type Definition" },
  },
}

