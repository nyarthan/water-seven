require("mini.completion").setup {
  lsp_completion = { source_func = "omnifunc", auto_setup = false },
}

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  MiniCompletion.get_lsp_capabilities { resolve_additional_text_edits = false }
)
capabilities.textDocument.formatting = nil
capabilities.textDocument.rangeFormatting = nil

vim.lsp.config("*", {
  capabilities = capabilities,
  init_options = { hostInfo = "neovim" },
  root_markers = { ".git/" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  pattern = "*",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.name ~= "oxfmt" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
    client.server_capabilities.semanticTokensProvider = nil
    vim.bo[args.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
  end,
})

-- sqls emits a window/showMessage "no database connection" in the brief window
-- before Neovim hands it the connection config; it connects fine right after.
-- Drop that one transient message, pass everything else through.
vim.lsp.config("sqls", {
  handlers = {
    ["window/showMessage"] = function(_, result)
      if result and result.message and result.message:find "no database connection" then return end
      local levels = { "ERROR", "WARN", "INFO", "DEBUG" }
      vim.notify("LSP[sqls] " .. result.message, vim.log.levels[levels[result.type] or "INFO"])
    end,
  },
})

vim.lsp.enable "eslint"
vim.lsp.enable "jsonls"
vim.lsp.enable "lua_ls"
vim.lsp.enable "nil_ls"
vim.lsp.enable "sqls"
vim.lsp.enable "tailwindcss"
vim.lsp.enable "ts_ls"
vim.lsp.enable "yamlls"
-- Recent Neovim nightlies break nvim-lspconfig's bundled oxfmt root_dir
-- (insert_package_json -> find on a table). Replace it with vim.fs.root.
vim.lsp.config("oxfmt", {
  root_dir = function(bufnr, on_dir)
    on_dir(
      vim.fs.root(
        bufnr,
        { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "package.json", ".git" }
      ) or vim.fn.getcwd()
    )
  end,
})
vim.lsp.enable "oxfmt"

local progress = vim.defaulttable()

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local value = event.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= "table" then return end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == event.data.params.token then
        p[i] = {
          token = event.data.params.token,
          msg = ("[%3d%%] %s%s"):format(
            value.kind == "end" and 100 or value.percentage or 100,
            value.title or "",
            value.message and (" **%s**"):format(value.message) or ""
          ),
          done = value.kind == "end",
        }
        break
      end
    end

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(
      function(v) return table.insert(msg, v.msg) or not v.done end,
      p
    )

    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(table.concat(msg, "\n"), vim.log.levels.INFO, {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and " "
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})
