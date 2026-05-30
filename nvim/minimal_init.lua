-- ==========================================================================
-- 1. DECLARE PLUGINS (Using Neovim's built-in vim.pack with full URLs)
-- ==========================================================================

vim.pack.add({
  -- Automatic parser downloader/manager for Treesitter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },

  -- Supercharged Rust LSP Experience (manages rust-analyzer)
  { src = "https://github.com/mrcjkb/rustaceanvim" },

  -- Direct file system editing buffer
  { src = "https://github.com/stevearc/oil.nvim" },
})

-- ==========================================================================
-- 2. ENABLING TREESITTER NATIVELY
-- ==========================================================================

-- Automate tracking and compiling of parsers via nvim-treesitter API
require("nvim-treesitter").install({ "rust", "toml" })

-- Activate Neovim's core parser engine on target filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust", "toml" },
  callback = function(args)
    -- Start syntax highlighting
    vim.treesitter.start()
    -- Automatically enable native LSP inlay hints
    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
  end,
})
-- Handle native autocompletion trigger loops asynchronously
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    
    -- Ensure the attached server (rust-analyzer) supports completion
    if client and client.supports_method("textDocument/completion") then
      -- Enable Neovim's built-in omnifunc-driven completion engine
      vim.lsp.completion.enable(true, client.id, args.buf, { 
        autotrigger = true,
        convert = function(item)
          return { abbr = item.label:gsub('%b()', '') }
        end, 
      })
    end
  end,
})

-- ==========================================================================
-- 3. PLUGIN CONFIGURATIONS
-- ==========================================================================

-- Configure Rustaceanvim
vim.g.rustaceanvim = {
  server = {
    -- Feed Neovim's default capabilities directly into the LSP
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    default_settings = {
      ['rust-analyzer'] = {
        check = { command = "clippy" },
        fmt = { enable = true },
      },
    },
  },
}

-- Configure Oil (File Browser)
require("oil").setup({
  default_file_explorer = true,
  view_options = { show_hidden = true }
})

-- ==========================================================================
-- 4. KEYMAPS & FORMATTING
-- ==========================================================================

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.wo.number = true
vim.wo.relativenumber = true
vim.g.have_nerd_font = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Diagnostic configuration
-- vim.diagnostic.config({
--   virtual_lines = true,
--   underline = true,
--   signs = true,
--   float = { border = "single" },
-- })

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Location list keymaps
vim.keymap.set('n', '<leader>ll', vim.diagnostic.setloclist, { desc = 'Show diagnostic location list' })
vim.keymap.set('n', '<leader>lc', vim.cmd.lclose, { desc = 'Close diagnostic location list' })
-- Next / previous in quickfix window
vim.keymap.set('n', '<M-j>', '<cmd>lnext<CR>', { desc = 'Location list next line' })
vim.keymap.set('n', '<M-k>', '<cmd>lprev<CR>', { desc = 'Location list previous line' })

vim.keymap.set('n', '<leader>vt', function()
  local show_text = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = show_text })
end, { desc = 'Toggle diagnostic [V]irtual [T]ext' })

vim.keymap.set('n', '<leader>vl', function()
  local show_lines = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = show_lines })
end, { desc = 'Toggle diagnostic [V]irtual [L]ines' })

vim.keymap.set('n', '<leader>th', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "[T]oggle [H]ints" })

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open Oil File Browser" })

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

