local config = require "diesel.config"
local install = require "diesel.install"

local M = {}

function M.check()
  local health = vim.health
  health.start "diesel.nvim"

  if vim.fn.has "nvim-0.10" == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error "Neovim 0.10 or newer is required"
  end

  if vim.fn.executable "node" == 1 then
    local version = vim.trim(vim.system({ "node", "--version" }, { text = true }):wait().stdout or "")
    health.ok("node " .. version .. " (" .. vim.fn.exepath "node" .. ")")
  else
    health.error("node is not on PATH", { "The language server is a Node script; install Node 18 or newer" })
  end

  if vim.fn.executable "git" == 1 then
    health.ok "git found"
  else
    health.warn("git is not on PATH", { "Needed to clone the server and the grammar" })
  end

  if not config.options.lsp.enable then
    health.info "language server disabled by config"
  elseif install.server_installed() then
    health.ok("language server at " .. config.server_dir())
  else
    health.warn("language server not installed", { "Run :DieselInstall, or open a .dsl file with lsp.auto_install on" })
  end

  local ts_ok = pcall(require, "nvim-treesitter")
  if not config.options.treesitter.enable then
    health.info "tree-sitter disabled by config"
  elseif not ts_ok then
    health.warn("nvim-treesitter not found", { "Highlighting needs nvim-treesitter to compile the grammar" })
  else
    local parser = vim.api.nvim_get_runtime_file("parser/diesel.so", false)[1]
    if parser then
      health.ok("grammar compiled at " .. parser)
    else
      health.warn("grammar not compiled yet", { "Run :TSInstall diesel, or open a .dsl file" })
    end
  end

  local queries = vim.api.nvim_get_runtime_file("queries/diesel/highlights.scm", true)
  if #queries > 0 then
    health.ok("highlight queries found (" .. #queries .. ")")
  else
    health.error "highlight queries missing from the runtimepath"
  end
end

return M
