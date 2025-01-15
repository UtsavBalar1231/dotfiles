---@class catdaddy.util.config: Options
local M = {}

---@class Options
---@field defaults defaults
local defaults = {
	icons = {
		misc = {
			dots = "󰇘",
		},
		ft = {
			octo = "",
		},
		dap = {
			Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
			Breakpoint = " ",
			BreakpointCondition = " ",
			BreakpointRejected = { " ", "DiagnosticError" },
			LogPoint = ".>",
		},
		diagnostics = {
			Error = " ",
			Warn = " ",
			Hint = " ",
			Info = " ",
		},
		git = {
			added = " ",
			modified = " ",
			removed = " ",
		},
		border = {
			{ '┌', 'FloatBorder' },
			{ '─', 'FloatBorder' },
			{ '┐', 'FloatBorder' },
			{ '│', 'FloatBorder' },
			{ '┘', 'FloatBorder' },
			{ '─', 'FloatBorder' },
			{ '└', 'FloatBorder' },
			{ '│', 'FloatBorder' },
		},
		kinds = {
			Array = " ",
			Boolean = "󰨙 ",
			Class = " ",
			Codeium = "󰘦 ",
			Color = " ",
			Control = " ",
			Collapsed = " ",
			Constant = "󰏿 ",
			Constructor = " ",
			Copilot = " ",
			Enum = " ",
			EnumMember = " ",
			Event = " ",
			Field = " ",
			File = " ",
			Folder = " ",
			Function = "󰊕 ",
			Interface = " ",
			Key = " ",
			Keyword = " ",
			Method = "󰊕 ",
			Module = " ",
			Namespace = "󰦮 ",
			Null = " ",
			Number = "󰎠 ",
			Object = " ",
			Operator = " ",
			Package = " ",
			Property = " ",
			Reference = " ",
			Snippet = "󱄽 ",
			String = " ",
			Struct = "󰆼 ",
			Supermaven = " ",
			TabNine = "󰏚 ",
			Text = " ",
			TypeParameter = " ",
			Unit = " ",
			Value = " ",
			Variable = "󰀫 ",
		},
	},
}

---@type Options
local options

---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
	local function _load(mod)
		if require("lazy.core.cache").find(mod)[1] then
			---@diagnostic disable-next-line: undefined-field
			Util.try(function()
				require(mod)
			end, { msg = "Failed loading " .. mod })
		end
	end
	local pattern = "Util" .. name:sub(1, 1):upper() .. name:sub(2)
	if M.defaults[name] or name == "options" then
		_load("catdaddy.util.config." .. name)
		vim.api.nvim_exec_autocmds("User", { pattern = pattern .. "Defaults", modeline = false })
	end
	_load("config." .. name)
	if vim.bo.filetype == "lazy" then
		vim.cmd([[do VimResized]])
	end
	vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
end

---@param opts? Options
function M.setup(opts)
	options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}

	-- autocmds can be loaded lazily when not opening a file
	local lazy_autocmds = vim.fn.argc(-1) == 0
	if not lazy_autocmds then
		M.load("autocmds")
	end

	local group = vim.api.nvim_create_augroup("Util", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "VeryLazy",
		callback = function()
			if lazy_autocmds then
				M.load("autocmds")
			end
			M.load("keymaps")

			Util.root.setup()

			vim.api.nvim_create_user_command("LazyHealth", function()
				vim.cmd([[Lazy! load all]])
				vim.cmd([[checkhealth]])
			end, { desc = "Load all plugins and run :checkhealth" })

			local health = require("lazy.health")
			vim.list_extend(health.valid, {
				"recommended",
				"desc",
				"vscode",
			})
		end,
	})
end

M.did_init = false
function M.init()
	if M.did_init then
		return
	end
	M.did_init = true
	local plugin = require("lazy.core.config").spec.plugins.Util
	if plugin then
		vim.opt.rtp:append(plugin.dir)
	end

	M.load("options")
end

setmetatable(M, {
	__index = function(_, key)
		if options == nil then
			return vim.deepcopy(defaults)[key]
		end
		---@cast options catdaddy.util.config
		return options[key]
	end,
})

return M
