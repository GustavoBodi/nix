vim.o.showtabline = 2
vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.termguicolors = true

-- Basic UX
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 300
vim.o.clipboard = "unnamedplus"

-- Load modules
require("keymaps")
require("bufferline")
require("treesitter")
require("lsp")

local transparent_groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "EndOfBuffer",
  "MsgArea",
  "BufferLineFill",
  "BufferLineBackground",
  "BufferLineTab",
}

for _, group in ipairs(transparent_groups) do
  vim.api.nvim_set_hl(0, group, { bg = "none" })
end
