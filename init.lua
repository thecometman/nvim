local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.showmode = false

vim.schedule(function()
	vim.o.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

vim.o.breakindent = true
vim.o.undofile = true
vim.o.signcolumn = "no"
vim.o.colorcolumn = "80"
vim.opt.isfname:append("@-@")

vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.termguicolors = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = "> ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split" --Not a misspelling

vim.o.cursorline = false
vim.o.scrolloff = 10
vim.o.confirm = true

vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"

local width = 2
vim.o.smartindent = true
vim.o.expandtab = true
vim.o.softtabstop = width
vim.o.shiftwidth = width
vim.o.tabstop = width
vim.o.cursorcolumn = false

require("keymaps")
local ui = { icons = vim.g.have_nerf_font and {} or {} }
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

--Runs multiple formatters sequentially on a specific filetype.
--You can use 'stop_after_first' to run the first available formatter from the list
--luau = { "stylua", "selene", stop_after_first = true },

local treesitter_config = {
	ensure_installed = {
		"bash",
		"rust",
		"c",
		"cpp",
		"cmake",
		"diff",
		"lua",
		"luadoc",
		"luau",
		"typescript",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
		"git_config",
		"git_rebase",
		"gitattributes",
		"gitcommit",
		"gitignore",
		"html",
		"json",
	},
	disable_identing = { "ruby" },
}

local enable_new_solver = true
local formatters_by_ft = {
	lua = { "selene", "stylua" },
	luau = { "selene", "stylua" },
}
local servers = {
	jsonls = {},
	selene = {},
	stylua = {},
	rust_analyzer = {},
	luau_lsp = {},
	lua_ls = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
				--Disables noisy missing fields
				diagnotstics = { disable = { "missing-fields" } },
			},
		},
	},
}

local generate_sourcemap = "a"

--[[
local colorscheme = {
	"rebelot/kanagawa.nvim",
	priority = 1000, -- Make sure to load this before all the other start plugins.
	config = function()
		---@diagnostic disable-next-line: missing-fields
		require("kanagawa").setup({
			styles = {
				commentStyle = { italic = false }, -- Disable italics in comments
			},
		})

		-- Load the colorscheme here.
		-- Like many other themes, this one has different styles, and you could load
		-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
		vim.cmd.colorscheme("kanagawa")
	end,
}
]]

---@param str string
---@return string[]
local function split_lines(str)
	---@type string[]
	local lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s)
	end
	return lines
end

local colorscheme = {
	"catppuccin/nvim",
	priority = 1000, -- Make sure to load this before all the other start plugins.
	config = function()
		---@diagnostic disable-next-line: missing-fields
		require("catppuccin").setup({
			flavour = "mocha",
		})

		-- Load the colorscheme here.
		-- Like many other themes, this one has different styles, and you could load
		-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
		vim.cmd.colorscheme("catppuccin")
	end,
}

local function rojo_project()
	return vim.fs.root(0, function(name)
		return name:match(".+%.project%.json$")
	end)
end

require("lazy").setup({
	{ import = "plugins" },
	colorscheme,

	--Detect tabstop and shiftwidth automatically
	"NMAC427/guess-indent.nvim",
	--//LSP
	{
		--`lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		--used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		--Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			--Status updates for LSP
			{ "j-hui/fidget.nvim", opts = {} },
			--Extra cpabilities
			"saghen/blink.cmp",
		},
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local ensure_installed = vim.tbl_keys(servers or {})
			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
			})

			require("mason-lspconfig").setup({
				ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
				automatic_enable = {
					exclude = { "luau_lsp" },
				},
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for ts_ls)
						server.capabilities = vim.tbl_deep_extend(
							"force",
							{},
							capabilities,
							server.capabilities or {}
						)
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({
						async = true,
						lsp_format = "fallback",
					})
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = formatters_by_ft,
		},
	},
	{ -- Autocompletion
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			-- Snippet Engine
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					-- {
					--   'rafamadriz/friendly-snippets',
					--   config = function()
					--     require('luasnip.loaders.from_vscode').lazy_load()
					--   end,
					-- },
				},
				opts = {},
			},
			"folke/lazydev.nvim",
		},
		--- @module 'blink.cmp'
		--- @type blink.cmp.Config
		opts = {
			keymap = {
				-- 'default' (recommended) for mappings similar to built-in completions
				--   <c-y> to accept ([y]es) the completion.
				--    This will auto-import if your LSP supports it.
				--    This will expand snippets if the LSP sent a snippet.
				-- 'super-tab' for tab to accept
				-- 'enter' for enter to accept
				-- 'none' for no mappings
				--
				-- For an understanding of why the 'default' preset is recommended,
				-- you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				--
				-- All presets have the following mappings:
				-- <tab>/<s-tab>: move to right/left of your snippet expansion
				-- <c-space>: Open menu or open docs if already open
				-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
				-- <c-e>: Hide menu
				-- <c-k>: Toggle signature help
				--
				-- See :h blink-cmp-config-keymap for defining your own keymap
				preset = "default",

				-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
				--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				-- By default, you may press `<c-space>` to show the documentation.
				-- Optionally, set `auto_show = true` to show the documentation after a delay.
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},

			sources = {
				default = { "lsp", "path", "snippets", "lazydev" },
				providers = {
					lazydev = {
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
				},
			},

			snippets = { preset = "luasnip" },

			-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
			-- which automatically downloads a prebuilt binary when enabled.
			--
			-- By default, we use the Lua implementation instead, but you may enable
			-- the rust implementation via `'prefer_rust_with_warning'`
			--
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = { implementation = "lua" },

			-- Shows a signature help window while you type arguments for a function
			signature = { enabled = true },
		},
	},

	{ --Luau LSP(+Roblox)
		"lopi-py/luau-lsp.nvim",
		opts = {
			fflags = {
				enable_new_solver = enable_new_solver,
				sync = true,
				override = {
					LuauTableTypeMaxmumStringifierLength = "100",
				},
			},
			platform = {
				type = rojo_project() and "roblox" or "standard",
			},
		},
		dependencies = { "nvim-lua/plenary.nvim" },
	},

	{ --Treesitter
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts

		opts = {
			ensure_installed = treesitter_config.ensure_installed, -- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
				-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
				--  If you are experiencing weird indenting issues, add the language to
				--  the list of additional_vim_regex_highlighting and disabled languages for indent.
				additional_vim_regex_highlighting = treesitter_config.disable_identing,
			},
			indent = { enable = true, disable = treesitter_config.disable_identing },
		},
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^6", -- Recommended
		lazy = false, -- This plugin is already lazy
	},
	-- VCS (Version Control System)
	{
		--:LazyJJ
		"swaits/lazyjj.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		opts = {},
	},
	{
		--Undotree
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		end,
	},

	--Fuzzy Finders
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			pcall(require("telescope").load_extension, "ui-select")
			local builtin = require("telescope.builtin")
			vim.keymap.set(
				"n",
				"<leader>tk",
				builtin.keymaps,
				{ desc = "[T]elescope [K]eymaps" }
			)
			vim.keymap.set(
				"n",
				"<leader>tf",
				builtin.find_files,
				{ desc = "[T]elescope [F]iles" }
			)
			vim.keymap.set(
				"n",
				"<leader>tg",
				builtin.live_grep,
				{ desc = "[T]elescoe [G]rep" }
			)
			vim.keymap.set(
				"n",
				"<leader>th",
				builtin.help_tags,
				{ desc = "[T]elescope [H]elp" }
			)
			vim.keymap.set(
				"n",
				"<leader>tb",
				builtin.buffers,
				{ desc = "[T]elescope [B]uffers" }
			)

			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(
					require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					})
				)
			end, { desc = "[/] Fuzzily search in current buffer" })
		end,
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup()

			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "[A]dd harpoon" })
			vim.keymap.set("n", "<C-e>", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "[E]xplore harpoon" })
			vim.keymap.set("n", "<C-h>", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<C-j>", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<C-k>", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<C-l>", function()
				harpoon:list():select(4)
			end)
		end,
	},

	--Session Saver
	{
		"Shatur/neovim-session-manager",
		config = function()
			local session_manager = require("session_manager")
			local config = require("session_manager.config")
			session_manager.setup({
				autoload_mode = config.AutoloadMode.Disabled, -- Define what to do when Neovim is started without arguments. See "Autoload mode" section below.
			})
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				callback = function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						-- Don't save while there's any 'nofile' buffer open.
						if
							vim.api.nvim_get_option_value("buftype", { buf = buf })
							== "nofile"
						then
							return
						end
					end
					session_manager.save_current_session()
				end,
			})
		end,
	},
}, { ui = ui })

--//Setup detection for sourcemap changes
vim.lsp.config("*", {
	capabilities = {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
	},
})

--//Setup jsonls (LSP for json) to recognize Rojo project files.
local schemas = {
	{
		name = "default.project.json",
		description = "JSON schema for Rojo project files",
		fileMatch = { "*.project.json" },
		url = "https://raw.githubusercontent.com/rojo-rbx/vscode-rojo/master/schemas/project.template.schema.json",
	},
}
vim.lsp.config("jsonls", {
	settings = {
		json = {
			schemas = schemas,
			validate = {
				enabled = true,
			},
		},
	},
})
