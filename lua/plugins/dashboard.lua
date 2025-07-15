return {
	"goolord/alpha-nvim",
	-- dependencies = { 'echasnovski/mini.icons' },
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local startify = require("alpha.themes.startify")
		-- available: devicons, mini, default is mini
		-- if provider not loaded and enabled is true, it will try to use another provider
		startify.file_icons.provider = "devicons"

		local start = require("start")
		require("alpha").setup(start.config)
	end,
}
