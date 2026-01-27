local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

-- Remap space
keymap("", "<Space>", "<Nop>", opts)

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)

-- Splits
keymap("n", "<C-w>h", ":split<CR>", opts)

-- Resize
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap("n", "<C-q>", ":bdelete!<CR>", opts)

-- Indentation
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move lines
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Clangd
keymap("n", "gh", "<Cmd>ClangdSwitchSourceHeader<CR>", opts)
keymap('n', '<A-i>', ":ToggleTerm<CR>", opts)
keymap('t', '<A-i>', "<Cmd>ToggleTerm<CR>", opts)
keymap("n", "ff", ":Telescope find_files<cr>", opts)
keymap("n", "fg", ":Telescope live_grep<cr>", opts)
keymap("n", "fb", ":Telescope file_browser<cr>", opts)
keymap("n", "fh", ":Telescope help_tags<cr>", opts)

