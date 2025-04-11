return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    {
      "L3MON4D3/LuaSnip",
      build = (function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
      dependencies = {
        {
          "rafamadriz/friendly-snippets",
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end,
        },
      },
    },
    "saadparwaiz1/cmp_luasnip",

    -- Adds other completion capabilities.
    --  nvim-cmp does not ship with all sources by default. They are split
    --  into multiple repos for maintenance purposes.
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-nvim-lsp-signature-help",
  },
  config = function()
    -- See `:help cmp`
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    luasnip.config.setup({})

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = "menu,menuone,noselect" },
      -- window borders
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      -- For an understanding of why these mappings were
      -- chosen, you will need to read `:help ins-completion`
      mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item(),        -- Select the [n]ext item
        ["<C-p>"] = cmp.mapping.select_prev_item(),        -- Select the [p]revious item
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept ([y]es) the completion.
      }),
      sources = {
        { name = "luasnip" },
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" },
        { name = "path" },
        { name = "buffer" },
      },
    })

    cmp.setup.filetype({ "sql" }, {
      sources = {
        { name = 'vim-dadbod-completion' },
        { name = "buffer" },
      }
    })

    -- Navigate to next/previous snippet token
    vim.keymap.set({'i','s'}, '<C-k>', function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      end
    end, { desc="Jump to next snippet token", silent=true })

    vim.keymap.set({'i','s'}, '<C-j>', function()
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      end
    end, { desc="Jump to previous snippet token", silent=true })

  end,
}
