vim.opt.showtabline = 2
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Basic UX
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.opt.clipboard = "unnamedplus"

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
