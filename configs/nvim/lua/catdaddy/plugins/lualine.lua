return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		local lualine = require("lualine")

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn", "info" },
			symbols = { error = " ", warn = " ", info = " " },
			update_in_insert = true,
			always_visible = false,
		}

		local diff = {
			"diff",
			colored = false,
			symbols = {
				modified = " ",
				added = " ",
				removed = " ",
			},
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
					return "(git: " .. str .. ")"
				end
			end,
		}

		local filename = {
			"filename",
			color = { gui = "italic" },
			file_status = true,
			shorting_target = 0,
			symbols = {
				readonly = "",
				modified = "",
				unreadable = "",
				new = "",
			},
			path = 3,
		}

		local filesize = {
			"filesize",
			cond = function()
				return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
			end,
			fmt = function(str)
				return string.format("%sb", str)
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
						return "TOF"
					end
				end
			end,
		}

		local codeium = {
			"codeium",
			color = { gui = "bold" },
			fmt = function(_)
				local cstr = require('codeium.virtual_text').status_string()
				if cstr == " ON" or cstr == " 0 " then
					return "{…}"
				elseif cstr == " * " then
					return "{…} 󰔟 "
				else
					return "" .. cstr
				end
			end,
		}

		lualine.setup({
			options = {
				globalstatus = true,
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
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
							modified = " ●",
							alternate_file = "",
							directory = "",
						},
						mode = 2,
					},
				},
				lualine_c = {
					filename,
					filesize,
					progress,
				},
				lualine_x = { diff, branch },
				lualine_y = {
					"searchcount",
					"selectioncount",
					"filetype",
				},
				lualine_z = {
					codeium,
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
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
