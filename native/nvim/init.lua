-- Authoritative Water Seven Neovim configuration.

vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })

local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
  telescope.setup({})
  local builtin = require("telescope.builtin")
  vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files" })
  vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Search text" })
end

local treesitter_ok, treesitter = pcall(require, "nvim-treesitter.configs")
if treesitter_ok then
  treesitter.setup({
    highlight = { enable = true },
    indent = { enable = true },
  })
end

local generated = vim.fn.stdpath("config") .. "/../water-seven/generated/neovim.lua"
if vim.uv.fs_stat(generated) then
  dofile(generated)
end

for _, server in ipairs(vim.g.water_seven_language_servers or {}) do
  if vim.lsp.config and vim.lsp.enable then
    vim.lsp.enable(server)
  end
end
