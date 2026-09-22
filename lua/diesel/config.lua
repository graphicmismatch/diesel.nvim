local M = {}

M.defaults = {
  -- Where the two halves of Diesel support come from. Both are plain git
  -- clones: the grammar is compiled by nvim-treesitter, and the server is
  -- dependency-free Node, so neither needs a build or package manager.
  lsp = {
    enable = true,
    url = "https://github.com/graphicmismatch/diesel-lsp",
    branch = "master",
    -- Set to a local checkout to develop against it instead of the clone.
    path = nil,
    -- Extra options merged into the vim.lsp.config entry (capabilities,
    -- on_attach, settings, ...).
    config = {},
    -- Clone the server automatically the first time a .dsl file is opened.
    auto_install = true,
  },
  treesitter = {
    enable = true,
    url = "https://github.com/graphicmismatch/diesel-treesitter",
    branch = "master",
    -- Set to a local checkout to develop against it instead of the clone.
    path = nil,
    -- Let nvim-treesitter compile the parser on the first .dsl file.
    auto_install = true,
  },
  -- `.dsl` is also used by other languages; set this false if you map the
  -- extension yourself.
  filetype = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

--- Directory the language server lives in: an explicit path if one was given,
--- otherwise the clone this plugin manages.
function M.server_dir()
  return M.options.lsp.path and vim.fn.expand(M.options.lsp.path)
    or vim.fs.joinpath(vim.fn.stdpath "data", "diesel", "diesel-lsp")
end

function M.server_script()
  return vim.fs.joinpath(M.server_dir(), "bin", "diesel-lsp.js")
end

--- Directory nvim-treesitter clones the grammar from. A local path is handed
--- to nvim-treesitter as-is; it clones from a path just as happily as a URL.
function M.grammar_source()
  return M.options.treesitter.path and vim.fn.expand(M.options.treesitter.path) or M.options.treesitter.url
end

return M
