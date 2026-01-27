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
  local map = vim.keymap.set

  map("n", "gD", vim.lsp.buf.declaration, opts)
  map("n", "gd", vim.lsp.buf.definition, opts)
  map("n", "gi", vim.lsp.buf.implementation, opts)
  map("n", "gt", vim.lsp.buf.type_definition, opts)
  map("n", "gr", vim.lsp.buf.references, opts)
  map("n", "K", vim.lsp.buf.hover, opts)
  map("n", "<C-k>", vim.lsp.buf.signature_help, opts)

  map("n", "<space>rn", vim.lsp.buf.rename, opts)
  map("n", "<space>f", vim.lsp.buf.format, opts)

  map("n", "<space>e", vim.diagnostic.open_float, opts)
  map("n", "[d", vim.diagnostic.goto_prev, opts)
  map("n", "]d", vim.diagnostic.goto_next, opts)
  map("n", "<space>q", vim.diagnostic.setloclist, opts)
  map("n", "<A-CR>", vim.lsp.buf.code_action, opts)
end

-- Servers
local servers = {
  "clangd",
  "csharp_ls",
  "pyright",
  "ts_ls",
  "bashls",
  "nil_ls",
}

for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
    on_attach = on_attach,
  })

  vim.lsp.enable(server)
end

