return {
	'stevearc/oil.nvim',
	opts = {},
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	config = function()
		require('oil').setup({
			default_file_explorer = true,
			columns = {
				"icon",
			},
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			delete_to_trash = true,
			skip_confirm_for_simple_edits = false,
			prompt_save_on_select_new_entry = true,
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				timeout_ms = 1000,
				autosave_changes = false,
			},
			constrain_cursor = "editable",
			watch_for_changes = false,
			keymaps = {
				["g?"] = "actions.show_help",
				["<CR>"] = "actions.select",
				["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
				["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
				["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
				["<C-p>"] = "actions.preview",
				["<C-c>"] = "actions.close",
				["<C-l>"] = "actions.refresh",
				["-"] = "actions.parent",
				["_"] = "actions.open_cwd",
				["`"] = "actions.cd",
				["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
				["gs"] = "actions.change_sort",
				["gx"] = "actions.open_external",
				["g."] = "actions.toggle_hidden",
				["g\\"] = "actions.toggle_trash",
			},
		})

		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open oil file manager" })
	end
}
