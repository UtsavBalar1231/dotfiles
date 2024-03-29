local status_ok, comment = pcall(require, "Comment")

if not status_ok then
	vim.notify("Missing Comment.nvim dependency", vim.log.levels.WARNING)
	return
end

comment.setup({
	-- Add a space b/w comment and the line
	padding = true,
	-- Whether the cursor should stay at its position
	sticky = true,
	-- LHS of toggle mappings in NORMAL mode
	toggler = {
		-- Line-comment toggle keymap
		line = "<leader>/",
		-- Block-comment toggle keymap
		block = "<leader>b",
	},

	-- LHS of operator-pending mappings in NORMAL/VISUAL mode
	opleader = {
		-- Line-comment keymap
		line = "<leader>/c",
		-- Block-comment keymap
		block = "<leader>/b",
	},
	pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
})
