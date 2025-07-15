vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- [Q]uickfix
vim.keymap.set(
	"n",
	"<leader>q",
	vim.diagnostic.setloclist,
	{ desc = "[Q]uickfix list" }
)

-- Exit terminal
vim.keymap.set(
	"t",
	"<Esc><Esc>",
	"<C-\\><C-n>",
	{ desc = "Exit terminal mode" }
)

--Disable arrows in normal mode
--vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
--vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
--vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
--vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- :help `windcmd`
-- Use CTRL+hjkl to navigate split windows.
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Focus bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Focus top window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })

-- (Shift) paragraph selected
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "k", ":m '<-2<cr>gv=gv")

-- Pasting over without taking register
vim.keymap.set("x", "<leader>p", '"_dP')

-- Quick explore
vim.keymap.set("n", "<leader>e", "<cmd>Ex<CR>")

-- Quick session
vim.keymap.set("n", "<leader>ls", "<cmd>SessionManager load_session<CR>")
