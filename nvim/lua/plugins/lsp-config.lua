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
        ensure_installed = { "lua_ls", "basedpyright", "rust_analyzer" }
      })
    end
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp' },

    config = function()
      local lspconfig = require("lspconfig")

      -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.basedpyright.setup({
        capabilities = capabilities
      })

      lspconfig.rust_analyzer.setup({
        settings = {}
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

          -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
          -- if client:supports_method('textDocument/completion') then
          --   vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
          -- end

          -- Auto-format ("lint") on save.
          -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
          if not client:supports_method('textDocument/willSaveWaitUntil')
              and client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = vim.api.nvim_create_augroup('lsp-attach', { clear = false }),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
              end,
            })
          end

          --Keymaps
          if client.supports_method('textDocument/hover') then
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Hover info about symbol" })
          end
          if client.supports_method('textDocument/definition') then
            vim.keymap.set('n', 'gd', require('telescope.builtin').lsp_definitions, { desc = "[G]oto [D]efinition" })
          end
          if client.supports_method('textDocument/documentSymbol') then
            vim.keymap.set('n', 'ds', require('telescope.builtin').lsp_document_symbols,
              { desc = "[D]ocument [S]ymbols" })
          end
          if client.supports_method('textDocument/formatting') then
            vim.keymap.set({ 'n', 'x' }, '<leader>bf', vim.lsp.buf.format, { desc = '[B]uffer [F]ormat' })
          end
          -- LSP Standard Keymaps      
          vim.keymap.set('n', 'grn', vim.lsp.buf.rename, {desc = 'Renames all references to the symbol under the cursor'})
          vim.keymap.set('n', 'gra', vim.lsp.buf.code_action, {desc = 'Code Action'})
          vim.keymap.set('n', 'grr', vim.lsp.buf.references, {desc = 'References to the symbol under the cursor'})
          vim.keymap.set('n', 'gri', vim.lsp.buf.implementation, {desc = 'Implementations for the symbol under the cursor'})
          vim.keymap.set('n', 'gO', vim.lsp.buf.document_symbol, {desc = 'Lists all symbols in the current buffer'})
          vim.keymap.set('i', '<C-S>', vim.lsp.buf.signature_help, {desc = 'Displays signature information about the symbol'})
        end,
      })
    end
  }
}
