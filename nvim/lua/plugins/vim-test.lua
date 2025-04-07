return {
  "vim-test/vim-test",
  dependencies = {
    "preservim/vimux"
  },

  config = function ()
    vim.keymap.set("n", "<leader>tn", ":TestNearest<CR>", {desc="[T]est [N]earest"})
    vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", {desc="[T]est [F]ile"})
    vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", {desc="[T]est [S]uite"})
    vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", {desc="[T]est [L]ast"})
    vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", {desc="[T]est [V]isit"})

    vim.cmd("let test#strategy = 'vimux'")
  end,
}
