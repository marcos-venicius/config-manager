return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
    config = function ()
      local function setup_keymaps()
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Hover & Signature
        map("n", "K", function()
          vim.lsp.buf.hover({ border = "rounded", max_height = 25, max_width = 120 })
        end, "Hover")

        -- gd, gD, gr, gi, gy handled by Snacks picker (snacks.lua)

        -- Diagnostics navigation
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev Diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")

        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<leader>e", vim.diagnostic.open_float, "Line Diagnostic")
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          setup_keymaps(bufnr)

          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Inlay hints disabled by default (toggle with <leader>lh)

          -- Document highlight on cursor hold
          if client.server_capabilities.documentHighlightProvider then
            local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E ",
            [vim.diagnostic.severity.WARN] = "W ",
            [vim.diagnostic.severity.INFO] = "I ",
            [vim.diagnostic.severity.HINT] = "H ",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
          }
        }
      })

      local mason_lspconfig = require("mason-lspconfig")
      local lspconfig = require("lspconfig")

      local function default_setup(server_name)
        lspconfig[server_name].setup({})
      end

      local handlers = {
        default_setup,
      }

      mason_lspconfig.setup({ handlers = handlers })
    end
  },
}
