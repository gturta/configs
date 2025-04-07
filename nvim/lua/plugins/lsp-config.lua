return {
  {
    'williamboman/mason.nvim',
    config = function()
      require("mason").setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright" }
      })
    end
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require("lspconfig")

      -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.pyright.setup({
        capabilities = capabilities
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(args)
          --keymaps
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client.supports_method('textDocument/hover') then
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, {desc="Hover info about symbol"} )
          end

          if client.supports_method('textDocument/definition') then
            vim.keymap.set('n', 'gd', require('telescope.builtin').lsp_definitions, {desc="[G]oto [D]efinition"} )
          end

          if client.supports_method('textDocument/documentSymbol') then
            vim.keymap.set('n', 'ds', require('telescope.builtin').lsp_document_symbols, {desc="[D]ocument [S]ymbols"} )
          end

          if client.supports_method('textDocument/codeAction') then
            vim.keymap.set({'n','x'}, '<leader>ca', vim.lsp.buf.code_action, {desc='[C]ode [A]ction'})
          end

          if client.supports_method('textDocument/formatting') then
            vim.keymap.set({'n','x'}, '<leader>gf', vim.lsp.buf.format, {desc='Buffer [F]ormat'})
          end

        end
      })
    end
  }
}
