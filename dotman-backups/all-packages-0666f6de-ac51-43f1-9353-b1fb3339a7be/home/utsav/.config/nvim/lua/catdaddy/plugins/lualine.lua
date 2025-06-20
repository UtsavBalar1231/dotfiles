return {
	"nvim-lualine/lualine.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	lazy = true,
	dependencies = {
		-- { "AndreM222/copilot-lualine" },
	},
	init = function()
		-- Show the current document symbols location from Trouble in lualine
		-- You can disable this for a buffer by setting vim.b.trouble_lualine = false
		vim.g.trouble_lualine = true

		vim.g.lualine_laststatus = vim.o.laststatus
		if vim.fn.argc(-1) > 0 then
			-- set an empty statusline till lualine loads
			vim.o.statusline = " "
		else
			-- hide the statusline on the starter page
			vim.o.laststatus = 0
		end
	end,
	opts = function()
		-- PERF: we don't need this lualine require madness 🤷
		local lualine_require = require("lualine_require")
		lualine_require.require = require
		local icons = Util.config.icons

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn", "info" },
			symbols = {
				error = icons.diagnostics.Error,
				warn = icons.diagnostics.Warn,
				info = icons.diagnostics.Info,
				hint = icons.diagnostics.Hint,
			},
			update_in_insert = true,
			always_visible = false,
		}

		local diff = {
			"diff",
			colored = false,
			symbols = {
				added = " ",
				modified = " ",
				removed = " ",
			},
			source = function()
				local gitsigns = vim.b.gitsigns_status_dict
				if gitsigns then
					return {
						added = gitsigns.added,
						modified = gitsigns.changed,
						removed = gitsigns.removed,
					}
				end
			end,
		}

		local branch = {
			"branch",
			icons_enabled = false,
			fmt = function(str)
				if str == nil or str == "" then
					local mode = vim.fn.mode()
					if mode == "n" then
						return "¯\\_(ツ)_/¯"
					elseif mode == "i" then
						return ">_> Typing..."
					elseif mode == "v" then
						return "[!] Sneaky Select"
					elseif mode == "V" then
						return "[!!] Big Select"
					elseif mode == "" then
						return "[###] Block Party"
					elseif mode == "R" then
						return "ಠ_ಠ Rewriting"
					elseif mode == "t" then
						return "O_o Terminal?"
					else
						return "(╯°□°)╯ What?!"
					end
				else
					return str
				end
			end,
		}

		local progress = {
			"progress",
			fmt = function(str)
				if not (str == "Top" or str == "Bot") then
					return str
				else
					if str == "Bot" then
						return "EOF"
					elseif str == "Top" then
						return "SOF"
					end
				end
			end,
		}

		local opts = {
			options = {
				globalstatus = vim.o.laststatus == 3,
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = { "alpha", "dashboard", "snacks_dashboard" },
				always_divide_middle = true,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					diagnostics,
					{
						"buffers",
						buffers_color = {
							active = { gui = "bold" },
							inactive = { gui = "italic" },
						},
						symbols = {
							modified = " ",
							alternate_file = "",
							directory = "",
						},
						mode = 2,
					},
				},
				lualine_c = {
					Util.lualine.root_dir(),
					"filesize",

					{
						"filetype",
						icon_only = true,
						separator = "",
						padding = { left = 1, right = 0 },
					},
					{ Util.lualine.pretty_path() },
				},
				lualine_x = {
					diff,
					branch,
				},
				lualine_y = {
					"searchcount",
					"selectioncount",
					progress,
				},
				lualine_z = {
					Snacks.profiler.status(),
				-- 	"copilot",
				},
			},
			inactive_sections = {
				lualine_a = { "mode" },
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			extensions = { "neo-tree", "lazy", "fzf" },
		}

		-- do not add trouble symbols if aerial is enabled
		-- And allow it to be overriden for some buffer types (see autocmds)
		local status_trouble, trouble = pcall(require, "trouble")
		if vim.g.trouble_lualine and status_trouble then
			local symbols = trouble.statusline({
				mode = "symbols",
				groups = {},
				title = false,
				filter = { range = true },
				format = "{kind_icon}{symbol.name:Normal}",
				hl_group = "lualine_c_normal",
			})
			table.insert(opts.sections.lualine_c, {
				symbols and symbols.get,
				cond = function()
					return vim.b.trouble_lualine ~= false and symbols.has()
				end,
			})
		end

		return opts
	end,
}
