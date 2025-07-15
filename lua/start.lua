local if_nil = vim.F.if_nil

local default_terminal = {
	type = "terminal",
	command = nil,
	width = 69,
	height = 8,
	opts = {
		redraw = true,
		window_config = {},
	},
}

local default_header = {
	type = "text",
	val = {
		[[ ______     ______     __    __     ______     ______  ]],
		[[/\  ___\   /\  __ \   /\ "-./  \   /\  ___\   /\__  _\ ]],
		[[\ \ \____  \ \ \/\ \  \ \ \-./\ \  \ \  __\   \/_/\ \/ ]],
		[[ \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_____\    \ \_\ ]],
		[[  \/_____/   \/_____/   \/_/  \/_/   \/_____/     \/_/ ]],
		[[                                                       ]],
	},
	opts = {
		position = "center",
		hl = "Boolean",
		-- wrap = "overflow";
	},
}

local footer = {
	type = "text",
	val = "",
	opts = {
		position = "center",
		hl = "Number",
	},
}

local leader = "<leader>"

--- @param sc string
--- @param txt string
--- @param keybind string? optional
--- @param keybind_opts table? optional
local function button(sc, txt, keybind, keybind_opts)
	local sc_ = sc:gsub("%s", ""):gsub(leader, "<leader>")

	local opts = {
		position = "center",
		shortcut = sc,
		cursor = 3,
		width = 50,
		align_shortcut = "right",
		hl_shortcut = "Keyword",
	}
	if keybind then
		--keybind_opts =
		--	if_nil(keybind_opts, { noremap = false, silent = true, nowait = true })
		opts.keymap = { "n", sc_, keybind, keybind_opts }
	end

	local function on_press()
		local key = vim.api.nvim_replace_termcodes(
			keybind or sc_ .. "<Ignore>",
			true,
			false,
			true
		)
		vim.api.nvim_feedkeys(key, "t", false)
	end

	return {
		type = "button",
		val = txt,
		on_press = on_press,
		opts = opts,
	}
end

local buttons = {
	type = "group",
	val = {
		button("w", "New file", "<cmd>ene <CR>"),
		button("a", "Telescope", "<cmd>Telescope<CR>"),
		button("s", "Resurrect session", "<leader>ls"),
		button("q", "Mason LSP", "<cmd>Mason<CR>"),
		button("e", "TSInstallInfo", "<cmd>TSInstallInfo<CR>"),
		button("d", "Help", "<cmd>Telescope help_tags<CR>"),
	},
	opts = {
		spacing = 1,
	},
}

local section = {
	terminal = default_terminal,
	header = default_header,
	buttons = buttons,
	footer = footer,
}

local config = {
	layout = {
		{ type = "padding", val = 2 },
		section.header,
		{ type = "padding", val = 2 },
		section.buttons,
		section.footer,
	},
	opts = {
		margin = 5,
	},
}

return {
	button = button,
	section = section,
	config = config,
	-- theme config
	leader = leader,
	-- deprecated
	opts = config,
}
