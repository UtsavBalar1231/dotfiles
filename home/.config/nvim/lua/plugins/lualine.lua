return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	init = function()
		vim.g.lualine_laststatus = vim.o.laststatus

		if vim.fn.argc(-1) > 0 then
			-- Prevent statusline flash on file open
			vim.o.statusline = " "
		else
			vim.o.laststatus = 0
		end
	end,
	opts = function()
		vim.o.laststatus = vim.g.lualine_laststatus

		local function copilot_status()
			local ok, copilot_client = pcall(require, "copilot.client")
			if not ok then
				return ""
			end

			if copilot_client.is_disabled() or not copilot_client.buf_is_attached(vim.api.nvim_get_current_buf()) then
				return ""
			end

			return LazyVim.config.icons.kinds.Copilot
		end

		local function lsp_clients()
			local ignore_list = { "copilot", "null-ls", "GitHub Copilot", "stylua" }
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return ""
			end

			local client_names = {}
			for _, client in ipairs(clients) do
				local ignored = false
				for _, ignore_name in ipairs(ignore_list) do
					if client.name == ignore_name then
						ignored = true
						break
					end
				end
				if not ignored then
					table.insert(client_names, client.name)
				end
			end

			if #client_names == 0 then
				return ""
			end

			return " " .. table.concat(client_names, ", ")
		end

		local function macro_recording()
			local recording_register = vim.fn.reg_recording()
			if recording_register == "" then
				return ""
			end
			return " @" .. recording_register
		end

		local function diff_source()
			local gitsigns = vim.b.gitsigns_status_dict
			if gitsigns then
				return {
					added = gitsigns.added,
					modified = gitsigns.changed,
					removed = gitsigns.removed,
				}
			end
		end

		return {
			options = {
				theme = "auto",
				globalstatus = true,
				component_separators = { left = "┃", right = "┃" },
				section_separators = { left = "", right = "" },
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
					refresh_time = 16,
					events = {
						"WinEnter",
						"BufEnter",
						"BufWritePost",
						"SessionLoadPost",
						"FileChangedShellPost",
						"VimResized",
						"Filetype",
						"CursorMoved",
						"CursorMovedI",
						"ModeChanged",
					},
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					{ macro_recording, color = "DiagnosticWarn" },
					{ "b:gitsigns_head", icon = LazyVim.config.icons.git.added, color = "String" },
					{
						"diff",
						source = diff_source,
						symbols = {
							added = LazyVim.config.icons.git.added,
							modified = LazyVim.config.icons.git.modified,
							removed = LazyVim.config.icons.git.removed,
						},
					},
				},
				lualine_c = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = {
							error = LazyVim.config.icons.diagnostics.Error,
							warn = LazyVim.config.icons.diagnostics.Warn,
							info = LazyVim.config.icons.diagnostics.Info,
							hint = LazyVim.config.icons.diagnostics.Hint,
						},
					},
					{ "filename", path = 1 },
					{ "searchcount" },
				},
				lualine_x = {
					{ lsp_clients, color = "Special" },
					{ copilot_status, color = "Comment" },
					"encoding",
					{
						"fileformat",
						symbols = {
							unix = "LF",
							dos = "CRLF",
							mac = "CR",
						},
					},
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			extensions = { "nvim-tree", "oil", "quickfix", "man", "lazy" },
		}
	end,
}
