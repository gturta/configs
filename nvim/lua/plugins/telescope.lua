return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzf-native.nvim',
    -- Useful for getting pretty icons, but requires a Nerd Font.
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' });
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' });
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' });
    vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]elect Telescope' });
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' });
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' });
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' });
    vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' });
    vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' });
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' });
  end
}
