-- Headless end-to-end test. Run with:
--
--   nvim --headless -u NONE -c 'lua dofile("test/run.lua")'
--
-- It drives the plugin the way an editor does: sets it up, opens a .dsl file,
-- and checks that the server was cloned and attached, that diagnostics,
-- completion and hover come back, and that the grammar compiled and highlights.
--
-- Point DIESEL_LSP_URL / DIESEL_TS_URL at local clones to test without network
-- (git clones from a path just as happily as from a URL).

local failures = 0
local function check(ok, what)
  print((ok and "ok   " or "FAIL ") .. what)
  if not ok then failures = failures + 1 end
end

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:append(root)

-- `-u NONE` starts with filetype detection off, and nvim-treesitter is only on
-- the runtimepath if this test is told where it lives.
vim.cmd "filetype plugin indent on"
local ts_plugin = os.getenv "DIESEL_TS_PLUGIN"
if ts_plugin then
  vim.opt.runtimepath:append(ts_plugin)
  require("nvim-treesitter.configs").setup { parser_install_dir = nil }
end

local data = vim.fn.tempname()
vim.fn.mkdir(data, "p")

require("diesel").setup {
  lsp = {
    url = os.getenv "DIESEL_LSP_URL" or "https://github.com/graphicmismatch/diesel-lsp",
    branch = "master",
  },
  treesitter = {
    url = os.getenv "DIESEL_TS_URL" or "https://github.com/graphicmismatch/diesel-treesitter",
    enable = os.getenv "DIESEL_SKIP_TS" == nil,
  },
}

-- Keep the clone inside the temp dir instead of the real stdpath("data").
local config = require "diesel.config"
config.options.lsp.path = nil
local real_server_dir = config.server_dir
config.server_dir = function()
  return config.options.lsp.path and vim.fn.expand(config.options.lsp.path) or (data .. "/diesel-lsp")
end

local source = [[patch "Check" {
    Phasor phasor1 { x = 0; y = 0; .frequency = 440; }
    "Audio Out" out1 { x = 260; y = 0; }
    Nope broken1;
    phasor1.out -> out1.in;
}
]]
local file = data .. "/check.dsl"
vim.fn.writefile(vim.split(source, "\n"), file)

vim.cmd("edit " .. file)
check(vim.bo.filetype == "diesel", "filetype is diesel (got " .. vim.bo.filetype .. ")")
check(vim.bo.commentstring == "// %s", "commentstring is set for gcc")

local client
vim.wait(60000, function()
  client = (vim.lsp.get_clients { bufnr = 0, name = "diesel" })[1]
  return client ~= nil
end, 250)
check(client ~= nil, "language server cloned and attached")

if client then
  local diagnostics = {}
  vim.wait(10000, function()
    diagnostics = vim.diagnostic.get(0)
    return #diagnostics > 0
  end, 200)
  check(#diagnostics == 1 and diagnostics[1].message:match "Unknown node type 'Nope'",
    "diagnostics: " .. (#diagnostics > 0 and diagnostics[1].message or "none"))

  local params = { textDocument = vim.lsp.util.make_text_document_params(0), position = { line = 4, character = 12 } }
  local completion = client:request_sync("textDocument/completion", params, 5000, 0)
  local labels = {}
  for _, item in ipairs(completion and completion.result and (completion.result.items or completion.result) or {}) do
    labels[#labels + 1] = item.label
  end
  check(#labels == 1 and labels[1] == "out", "port completion after 'phasor1.' = " .. vim.inspect(labels))

  params.position = { line = 1, character = 5 }
  local hover = client:request_sync("textDocument/hover", params, 5000, 0)
  local contents = hover and hover.result and hover.result.contents.value or ""
  check(contents:match "%*%*Phasor%*%*", "hover shows the node type and its ports")
end

if os.getenv "DIESEL_SKIP_TS" == nil then
  vim.wait(120000, function()
    return #vim.api.nvim_get_runtime_file("parser/diesel.so", false) > 0
  end, 1000)
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "diesel")
  check(ok and parser ~= nil, "tree-sitter parser compiled and loaded")
  if ok and parser then
    local tree = parser:parse()[1]
    check(not tree:root():has_error(), "the file parses without errors")
    local query = vim.treesitter.query.get("diesel", "highlights")
    local captures = 0
    if query then
      for _ in query:iter_captures(tree:root(), 0, 0, -1) do captures = captures + 1 end
    end
    check(captures > 20, "highlight query matched " .. captures .. " captures")
  end
end

print(failures == 0 and "\nALL PASS" or ("\n" .. failures .. " FAILED"))
vim.cmd(failures == 0 and "qa!" or "cq")
