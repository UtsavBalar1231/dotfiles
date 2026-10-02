---@class util.url
local M = {}

-- URL matching pattern (supports protocols like http, https, ftp, file, etc.)
M.url_pattern =
	"\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*\\})\\})+"

-- Highlight group for URLs
local function setup_highlight()
	vim.api.nvim_set_hl(0, "URL", {
		underline = true,
		fg = "#7daea3",
		cterm = {
			underline = true,
		},
		ctermfg = 109,
	})
end

-- Auto command to highlight URLs
local function setup_autocmd()
	local augroup = vim.api.nvim_create_augroup("URL", { clear = true })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter", "WinEnter" }, {
		group = augroup,
		pattern = "*",
		desc = "Highlight URLs",
		callback = function()
			vim.fn.clearmatches()
			vim.fn.matchadd("URL", M.url_pattern)
		end,
	})
end

-- Extract all URL positions from a line for cursor-based selection
---@param line string
---@return table
local function find_urls(line)
	local matches = {}
	local start_pos = 1

	while true do
		local match_start, match_end = line:find(M.url_pattern, start_pos)
		if not match_start then
			break
		end
		table.insert(matches, { start = match_start, finish = match_end })
		start_pos = match_end + 1
	end

	return matches
end

-- Function to open the URL under the cursor
---@return nil
function M.open_url()
	local line = vim.fn.getline(".")
	local cursor_col = vim.fn.col(".")

	-- Find all URL matches in the line
	local matches = find_urls(line)

	-- Check if the cursor is over any match
	for _, match in ipairs(matches) do
		if cursor_col >= match.start and cursor_col <= match.finish then
			local url = line:sub(match.start, match.finish)
			-- Add default scheme if missing
			if not url:match("^[a-z]+://") then
				url = "http://" .. url
			end
			vim.fn.jobstart({ "xdg-open", url }, { detach = true })
			return
		end
	end

	vim.notify("No URL found under the cursor.", vim.log.levels.WARN)
end

-- Custom command to open URL under cursor
local function setup_user_command()
	vim.api.nvim_create_user_command("OpenUrl", M.open_url, { desc = "Open the URL under the cursor" })
end

-- Keymap for opening URLs
local function setup_keymap()
	vim.api.nvim_set_keymap("n", "<leader>mu", ":OpenUrl<CR>", { noremap = true, silent = true })
end

-- Setup function to initialize the module
function M.setup()
	setup_highlight()
	setup_autocmd()
	setup_user_command()
	setup_keymap()
end

return M
