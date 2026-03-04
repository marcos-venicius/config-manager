return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      }

      vim.keymap.set('n', '<leader>g', require('telescope.builtin').live_grep, { desc = 'Grep Files' })
      vim.keymap.set('n', '<leader>f', require('telescope.builtin').git_files, { desc = 'Find Git Files' })
      vim.keymap.set('n', '<leader>F', require('telescope.builtin').find_files, { desc = 'Find Files' })
      vim.keymap.set('n', '<leader>d', require('telescope.builtin').diagnostics, { desc = 'Diagnostics' })
      vim.keymap.set('n', '<leader>b', require('telescope.builtin').buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>lc', require('telescope.builtin').git_commits, { desc = 'List Git Commits' })
      vim.keymap.set('n', '<leader>lb', require('telescope.builtin').git_branches, { desc = 'List Git Branches' })
    end
  }
}

