-- Blink.cmp integration: hide copilot suggestions when completion menu is open
-- vim.api.nvim_create_autocmd("User", {
-- 	pattern = "BlinkCmpMenuOpen",
-- 	callback = function()
-- 		vim.b.copilot_suggestion_hidden = true
-- 	end,
-- })
--
-- vim.api.nvim_create_autocmd("User", {
-- 	pattern = "BlinkCmpMenuClose",
-- 	callback = function()
-- 		vim.b.copilot_suggestion_hidden = false
-- 	end,
-- })

return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		-- Enable copilot in filetypes disabled by the LazyVim ai.copilot extra
		filetypes = {
			markdown = true,
			help = true,
		},
	},
}
