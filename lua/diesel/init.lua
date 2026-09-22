local config = require "diesel.config"
local install = require "diesel.install"

local M = {}

local group = vim.api.nvim_create_augroup("diesel.nvim", { clear = true })
local requested = false

--- Registers the grammar with nvim-treesitter.
---
--- This runs from a FileType autocmd rather than at setup() time on purpose:
--- requiring nvim-treesitter.parsers forces the plugin to load and run its own
--- setup (ensure_installed included) before this registration exists, which
--- both defeats its lazy-loading and makes that install pass fail on "diesel".
--- Registered from an autocmd created at setup, this runs before
--- nvim-treesitter's own FileType handler - same event, earlier definition - so
--- auto_install sees the parser and builds it on the first .dsl buffer.
local function register_grammar()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then return end

  local configs = parsers.get_parser_configs and parsers.get_parser_configs() or parsers
  if configs.diesel then return end
  configs.diesel = {
    install_info = {
      url = config.grammar_source(),
      files = { "src/parser.c" },
      branch = config.options.treesitter.branch,
      generate_requires_npm = false,
      requires_generate_from_grammar = false,
    },
    filetype = "diesel",
  }

  if config.options.treesitter.auto_install then
    -- nvim-treesitter's own auto_install may or may not have a FileType
    -- handler, and if it does it may run before this one (plugin load order is
    -- not ours to control), in which case it saw no diesel parser and skipped.
    -- Ask for the parser ourselves, once per session, if it is still missing.
    vim.schedule(function()
      if not requested and #vim.api.nvim_get_runtime_file("parser/diesel.so", false) == 0 then
        requested = true
        pcall(vim.cmd, "TSInstall diesel")
      end
    end)
  end
end

local function start_server(bufnr)
  if not config.options.lsp.enable then return end
  if vim.fn.executable "node" == 0 then return end
  if not install.server_installed() then
    if not config.options.lsp.auto_install then return end
    if not install.install_server { silent = false } then return end
  end

  local options = vim.tbl_deep_extend("force", {
    cmd = { "node", config.server_script() },
    filetypes = { "diesel" },
    -- A .dsl patch is self-contained: it embeds its samples and subpatches,
    -- so the file's own directory is as much of a project root as exists.
    root_dir = function(buf, on_dir) on_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(buf))) end,
    capabilities = M.capabilities(),
  }, config.options.lsp.config)

  if vim.lsp.config then
    vim.lsp.config("diesel", options)
    vim.lsp.enable "diesel"
    -- vim.lsp.enable only attaches to buffers opened after it runs, so the
    -- buffer that triggered this needs starting by hand.
    options.name = "diesel"
    options.root_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    vim.lsp.start(options, { bufnr = bufnr })
  else
    options.name = "diesel"
    options.root_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    vim.lsp.start(options, { bufnr = bufnr })
  end
end

--- Client capabilities, with nvim-cmp's or blink.cmp's additions when present.
function M.capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if cmp_ok then return cmp_lsp.default_capabilities(capabilities) end
  local blink_ok, blink = pcall(require, "blink.cmp")
  if blink_ok and blink.get_lsp_capabilities then return blink.get_lsp_capabilities(capabilities) end
  return capabilities
end

function M.setup(opts)
  config.setup(opts)

  if config.options.filetype then
    vim.filetype.add { extension = { dsl = "diesel" } }
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "diesel",
    callback = function(args)
      if config.options.treesitter.enable then register_grammar() end
      start_server(args.buf)
    end,
  })
end

M.install = install.install_server
M.update = install.update
M.info = install.info

return M
