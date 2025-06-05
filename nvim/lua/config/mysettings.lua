vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.wo.number = true
vim.wo.relativenumber = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true
-- Save undo history
vim.opt.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'
-- Decrease update time
vim.opt.updatetime = 250
-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
--window borders
vim.opt.winborder = 'rounded'

-- Buffer delete and switch to previous
vim.keymap.set('n', '<leader>bd', ':bp | bd#<CR>', { desc = '[B]uffer [d]elete and switch to previous' })

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_lines = true,
  underline = true,
  signs = true,
  float = { border = "single" },
})

-- Location list keymaps
vim.keymap.set('n', '<leader>ll', vim.diagnostic.setloclist, { desc = 'Show diagnostic location list' })
vim.keymap.set('n', '<leader>lc', vim.cmd.lclose, { desc = 'Close diagnostic location list' })
-- Next / previous in quickfix window
vim.keymap.set('n', '<M-j>', '<cmd>lnext<CR>', { desc = 'Location list next line' })
vim.keymap.set('n', '<M-k>', '<cmd>lprev<CR>', { desc = 'Location list previous line' })

vim.keymap.set('n', '<leader>tv', function()
  local show_text = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = show_text })
end, { desc = '[T]oggle diagnostic [V]irtual lines' })

vim.keymap.set('n', '<leader>th', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "[T]oggle [H]ints" })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- JSON formatting
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  desc = 'Format json with jq',
  pattern = '*.json',
  callback = function()
    vim.opt.formatprg = 'jq'
  end,
})

-- Window resizing
vim.keymap.set('n', '<M-,>', '<C-w>5<', { desc = "Window width shrink by 5" })
vim.keymap.set('n', '<M-.>', '<C-w>5>', { desc = "Window width increase by 5" })
vim.keymap.set('n', '<M-<>', '<C-w>5-', { desc = "Window height shrink by 5" })
vim.keymap.set('n', '<M->>', '<C-w>5+', { desc = "Window height increase by 5" })

vim.lsp.enable({'rust_analyzer', 'zls'})

