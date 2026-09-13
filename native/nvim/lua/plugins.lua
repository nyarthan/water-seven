require("mini.icons").setup()

require("mini.bracketed").setup {
  buffer = { suffix = "b", options = {} },
  comment = { suffix = "c", options = {} },
  conflict = { suffix = "x", options = {} },
  diagnostic = { suffix = "d", options = {} },
  file = { suffix = "f", options = {} },
  indent = { suffix = "i", options = {} },
  jump = { suffix = "j", options = {} },
  location = { suffix = "l", options = {} },
  oldfile = { suffix = "o", options = {} },
  quickfix = { suffix = "p", options = {} },
  treesitter = { suffix = "t", options = {} },
  undo = { suffix = "u", options = {} },
  window = { suffix = "w", options = {} },
  yank = { suffix = "y", options = {} },
}

require("mini.diff").setup {
  view = { style = "sign", priority = 199 },
  mappings = {
    apply = "gh",
    reset = "gH",
    textobject = "gh",
    goto_first = "[H",
    goto_prev = "[h",
    goto_next = "]h",
    goto_last = "]H",
  },
}

local files = require "mini.files"
files.setup { windows = { preview = true } }

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename",
  callback = function(event) Snacks.rename.on_rename_file(event.data.from, event.data.to) end,
})

vim.keymap.set(
  "n",
  "<leader>e",
  function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end,
  { desc = "Open File [E]xplorer" }
)

local hipatterns = require "mini.hipatterns"
hipatterns.setup {
  highlighters = {
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
    note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
}

local indentscope = require "mini.indentscope"
indentscope.setup {
  draw = {
    delay = 0,
    animation = indentscope.gen_animation.none(),
  },
}

require("mini.jump").setup {
  mappings = {
    forward = "f",
    backward = "F",
    forward_till = "t",
    backward_till = "T",
    repeat_jump = ";",
  },
}

require("mini.move").setup {
  mappings = {
    left = "<M-h>",
    right = "<M-l>",
    down = "<M-j>",
    up = "<M-k>",
    line_left = "<M-h>",
    line_right = "<M-l>",
    line_down = "<M-j>",
    line_up = "<M-k>",
  },
}

require("mini.pairs").setup {}

require("mini.pick").setup {
  mappings = { choose_marked = "<C-q>" },
}

vim.keymap.set("n", "<leader>ff", function() MiniPick.builtin.files() end, { desc = "Find Files" })
vim.keymap.set(
  "n",
  "<leader>fg",
  function() MiniPick.builtin.grep_live() end,
  { desc = "Find Grep" }
)
vim.keymap.set(
  "n",
  "<leader>fr",
  function() MiniPick.builtin.resume() end,
  { desc = "Find Resume" }
)

require("mini.sessions").setup {}

require("mini.starter").setup {
  -- font: DOS Rebel
  header = [[
                                         ███
                                        ░░░
 ████████    ██████   ██████  █████ █████ ████  █████████████
░░███░░███  ███░░███ ███░░███░░███ ░░███ ░░███ ░░███░░███░░███
 ░███ ░███ ░███████ ░███ ░███ ░███  ░███  ░███  ░███ ░███ ░███
 ░███ ░███ ░███░░░  ░███ ░███ ░░███ ███   ░███  ░███ ░███ ░███
 ████ █████░░██████ ░░██████   ░░█████    █████ █████░███ █████
░░░░ ░░░░░  ░░░░░░   ░░░░░░     ░░░░░    ░░░░░ ░░░░░ ░░░ ░░░░░ ]],
}

local statusline = require "mini.statusline"
statusline.setup {
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
      local git = statusline.section_git { trunc_width = 40 }
      local diff = statusline.section_diff { trunc_width = 75 }
      local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
      local filename = statusline.section_filename { trunc_width = 140 }
      local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
      local location = statusline.section_location { trunc_width = 75 }
      local search = statusline.section_searchcount { trunc_width = 75 }
      local lsp = statusline.section_lsp { trunc_width = 75 }

      return statusline.combine_groups {
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevInfo", strings = { git, diff, diagnostics, lsp } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = mode_hl, strings = { search, location } },
      }
    end,
  },
}

require("mini.surround").setup {
  mappings = {
    add = "sa",
    delete = "sd",
    find = "sf",
    find_left = "sF",
    highlight = "sh",
    replace = "sr",
    update_n_lines = "sn",
  },
}

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then return end
    local ok, ts = pcall(require, "nvim-treesitter")
    if ok and type(ts.indentexpr) == "function" then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require("nvim-ts-autotag").setup {
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = true,
  },
}

require("ts_context_commentstring").setup { enable_autocmd = false }

local get_option = vim.filetype.get_option
---@diagnostic disable-next-line: duplicate-set-field
vim.filetype.get_option = function(filetype, option)
  if option == "commentstring" then
    return require("ts_context_commentstring.internal").calculate_commentstring()
  else
    return get_option(filetype, option)
  end
end

require("snacks").setup {
  bigfile = { enabled = true },
  bufdelete = { enabled = true },
  quickfile = { enabled = true },
  rename = { enabled = true },
  picker = { enabled = false },
  statuscolumn = {
    enabled = true,
    left = { "mark", "sign" },
    right = { "fold", "git" },
    folds = { open = false, git_hl = false },
    git = { patterns = { "GitSign", "MiniDiffSign" } },
    refresh = 50,
  },
}

require("trouble").setup { focus = true }

require("conform").setup {
  formatters = {
    oxfmt = {
      command = "oxfmt",
      args = { "--stdin-filepath", "$FILENAME" },
      stdin = true,
    },
    sql_formatter = {
      -- Treat ${...} JS interpolations as params so sql-formatter formats inline
      prepend_args = {
        "--config",
        [==[{"language":"sqlite","paramTypes":{"custom":[{"regex":"\\$\\{[^}]*\\}"}]}}]==],
      },
    },
    injected = {
      options = { ignore_errors = true },
    },
  },
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "nixfmt" },
    typescript = { "oxfmt", "injected" },
    javascript = { "oxfmt", "injected" },
    sql = { "sql_formatter" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
}

require("otter").setup {}

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  callback = function() require("otter").activate { "sql" } end,
})

vim.cmd "packadd justify"
vim.cmd "packadd nvim.undotree"
vim.keymap.set("n", "<lader>u", require("undotree").open)
