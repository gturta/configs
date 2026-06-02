
-- ============================================================================
-- 1. CORE OPTIONS
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.wo.number = true
vim.wo.relativenumber = true
vim.g.have_nerd_font = true

vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.winborder = 'rounded'

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)


-- ==========================================================================
-- 2. PLUGINS
-- ==========================================================================

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/mrcjkb/rustaceanvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/catppuccin/nvim" },
})


-- ============================================================================
-- 3. PLUGIN SETUP
-- ============================================================================

-- Treesitter
require("nvim-treesitter").install({ "rust", "toml" })

-- Rustaceanvim
vim.g.rustaceanvim = {
  server = {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
        fmt = { enable = true },
      },
    },
  },
}

-- Oil
require("oil").setup({
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
  },
})

-- Telescope
local telescope = require("telescope")
local telescope_builtin = require("telescope.builtin")
local telescope_actions = require("telescope.actions")

telescope.setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_config = {
      prompt_position = "top",
    },
    mappings = {
      i = {
        ["<Esc>"] = telescope_actions.close,
      },
    },
  },
})

-- Catppuccin colorscheme
vim.cmd.colorscheme("catppuccin")

-- ============================================================================
-- 4. AUTOCOMMANDS
-- ============================================================================

-- Enable Treesitter and inlay hints for selected filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust", "toml" },
  callback = function(args)
    vim.treesitter.start()
    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
  end,
})

-- Enable native completion when LSP supports it
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = function(item)
          return { abbr = item.label:gsub("%b()", "") }
        end,
      })
    end
  end,
})

-- ============================================================================
-- 5. KEYMAPS
-- ============================================================================

-- ========= Diagnostics / location list ==========
vim.keymap.set("n", "<leader>ll", vim.diagnostic.setloclist, {
  desc = "Show diagnostic location list",
})

vim.keymap.set("n", "<leader>lc", vim.cmd.lclose, {
  desc = "Close diagnostic location list",
})

vim.keymap.set("n", "<M-j>", "<cmd>lnext<CR>", {
  desc = "Location list next line",
})

vim.keymap.set("n", "<M-k>", "<cmd>lprev<CR>", {
  desc = "Location list previous line",
})

vim.keymap.set("n", "<leader>vt", function()
  local show_text = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = show_text })
end, {
  desc = "Toggle diagnostic virtual text",
})

vim.keymap.set("n", "<leader>vl", function()
  local show_lines = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = show_lines })
end, {
  desc = "Toggle diagnostic virtual lines",
})

vim.keymap.set("n", "<leader>th", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, {
  desc = "Toggle inlay hints",
})

-- ========= Oil =========
vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
  desc = "Open Oil file browser",
})

-- ========= Telescope =========
vim.keymap.set("n", "<leader>ff", telescope_builtin.find_files, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", telescope_builtin.live_grep, {
  desc = "Live grep",
})

vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, {
  desc = "Find buffers",
})

vim.keymap.set("n", "<leader>fh", telescope_builtin.help_tags, {
  desc = "Help tags",
})

-- ========= Terminal window =========
vim.keymap.set('n', '<leader>ti', function()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(current_tab)
  
  -- 1. Scan all open windows in the current tab for a terminal
  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    
    if buftype == 'terminal' then
      -- Found an existing terminal window! Switch to it.
      vim.api.nvim_set_current_win(win)
      vim.cmd('startinsert')
      return
    end
  end

  -- 2. If no terminal window was found, create a new one
  vim.cmd('botright 15split')
  vim.cmd('terminal')
  vim.cmd('startinsert')
end, { desc = 'Toggle/Go to terminal split' })

-- Easy window navigation from terminal insert mode
vim.keymap.set('t', '<C-w>h', [[<C-\><C-n><C-w>h]], { desc = 'Move to left window' })
vim.keymap.set('t', '<C-w>j', [[<C-\><C-n><C-w>j]], { desc = 'Move to bottom window' })
vim.keymap.set('t', '<C-w>k', [[<C-\><C-n><C-w>k]], { desc = 'Move to top window' })
vim.keymap.set('t', '<C-w>l', [[<C-\><C-n><C-w>l]], { desc = 'Move to right window' })
