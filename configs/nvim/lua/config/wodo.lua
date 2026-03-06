local function AddTodoBoilerplate()
    local date = os.date("%A %d-%m-%y %H:%M - %H:%M")
    local text = '"" ' .. date .. ' Todo'

    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line = vim.api.nvim_get_current_line()

    if line == "" then
        vim.api.nvim_set_current_line(text)
    else
        vim.api.nvim_buf_set_lines(0, row + 1, row + 1, false, { text })
        vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
    end
end

local function set_state(state)
    local line = vim.api.nvim_get_current_line()

    if string.match(line, "Todo$") then
        line = line:gsub(" Todo$", " " .. state)
    elseif string.match(line, "Doing$") then
        line = line:gsub(" Doing$", " " .. state)
    elseif string.match(line, "Done$") then
        line = line:gsub(" Done$", " " .. state)
    end

    vim.api.nvim_set_current_line(line)
end

local group = vim.api.nvim_create_augroup("TodoListFile", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = group,
    pattern = "*.wodo",
    callback = function()
        vim.keymap.set("n", "<leader>t", function() set_state("Todo") end, { buffer = true })
        vim.keymap.set("n", "<leader>i", function() set_state("Doing") end, { buffer = true })
        vim.keymap.set("n", "<leader>c", function() set_state("Done") end, { buffer = true })
        vim.keymap.set("n", "<leader>a", AddTodoBoilerplate, { buffer = true })
    end,
})
