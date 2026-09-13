local function map(mode, lhs, rhs, opts) vim.keymap.set(mode, lhs, rhs, opts) end

local function cmd(s) return "<Cmd>" .. s .. "<CR>" end

-- Basic
map("n", "<Esc>", cmd "nohlsearch", { desc = "Stop highlighting current search" })
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
map("n", "gd", function() vim.lsp.buf.definition() end, { desc = "[G]o to [D]efinition" })
map("n", "<leader>ga", function() vim.lsp.buf.code_action() end, { desc = "[G]o, Code [Action]!" })

-- Trouble
map("n", "<leader>xx", cmd "Trouble diagnostics toggle", { desc = "Diagnostics (Trouble)" })
map(
  "n",
  "<leader>xX",
  cmd "Trouble diagnostics toggle filter.buf=0",
  { desc = "Buffer Diagnostics (Trouble)" }
)
map("n", "<leader>xs", cmd "Trouble symbols toggle focus=false", { desc = "Symbols (Trouble)" })
map(
  "n",
  "<leader>xl",
  cmd "Trouble lsp toggle focus=false win.position=right",
  { desc = "LSP Definitions / references / ..." }
)
map("n", "<leader>xL", cmd "Trouble loclist toggle", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", cmd "Trouble qflist toggle", { desc = "Quickfix List (Trouble)" })
