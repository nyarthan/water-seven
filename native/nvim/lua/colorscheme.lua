local palette = {
  base00 = "#080808",
  base01 = "#141414",
  base02 = "#1C1C1C",
  base03 = "#505050",
  base04 = "#A0A0A0",
  base05 = "#EDE5DB",
  base06 = "#F2ECE4",
  base07 = "#F7F2EC",
  base08 = "#FF8080",
  base09 = "#FFC799",
  base0A = "#FFC799",
  base0B = "#99FFE4",
  base0C = "#A0A0A0",
  base0D = "#FFC799",
  base0E = "#A0A0A0",
  base0F = "#FF8080",
}

require("mini.base16").setup {
  palette = palette,
}

vim.api.nvim_set_hl(0, "@variable", { fg = palette.base05 })
vim.api.nvim_set_hl(0, "@property", { fg = palette.base05 })
vim.api.nvim_set_hl(0, "@variable.parameter", { fg = palette.base05 })
vim.api.nvim_set_hl(0, "@variable.member", { fg = palette.base05 })
vim.api.nvim_set_hl(0, "@tag", { fg = palette.base09 })
vim.api.nvim_set_hl(0, "@tag.attribute", { fg = palette.base09 })
