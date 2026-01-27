local lspconfig = require("lspconfig")
local cmp = require("cmp")

vim.diagnostic.config({
  virtual_text = true,
})

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = "nvim_lsp" },
  },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local keymap = vim.keymap.set

  keymap("n", "gD", vim.lsp.buf.declaration, opts)
  keymap("n", "gd", vim.lsp.buf.definition, opts)
  keymap("n", "gi", vim.lsp.buf.implementation, opts)
  keymap("n", "gt", vim.lsp.buf.type_definition, opts)
  keymap("n", "gr", vim.lsp.buf.references, opts)
  keymap("n", "K", vim.lsp.buf.hover, opts)
  keymap("n", "<C-k>", vim.lsp.buf.signature_help, opts)

  keymap("n", "<space>rn", vim.lsp.buf.rename, opts)
  keymap("n", "<space>f", vim.lsp.buf.format, opts)

  keymap("n", "<space>e", vim.diagnostic.open_float, opts)
  keymap("n", "[d", vim.diagnostic.goto_prev, opts)
  keymap("n", "]d", vim.diagnostic.goto_next, opts)
  keymap("n", "<space>q", vim.diagnostic.setloclist, opts)
  keymap("n", "<A-CR>", vim.lsp.buf.code_action, opts)
end

local servers = {
  "clangd",
  "csharp_ls",
  "pyright",
  "tsserver",
  "bashls",
  "nil_ls",
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
  })
end
