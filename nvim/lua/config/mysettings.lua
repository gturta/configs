vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.wo.number = true

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

-- Buffer delete and switch to previous
vim.keymap.set('n', '<leader>bd', ':bp | bd#<CR>', { desc = '[B]uffer [d]elete and switch to previous'} )

-- Diagnostic keymaps
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  signs = true,
  float = { border = "single" },
})
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', 'gK', function()
  local show_text = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = show_text })
end, { desc = 'Toggle diagnostic virtual lines' })


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
