return {
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      local gs = require('gitsigns')

      gs.setup {
        current_line_blame = true
      }

      vim.keymap.set('n', ']c', function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, {expr=true, desc = "Jump to next hunk"})

      vim.keymap.set('n', '[c', function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, {expr=true, desc = "Jump to previous hunk"})
    end
  }
}

