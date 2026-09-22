local config = require "diesel.config"

local M = {}

local function notify(message, level)
  vim.notify("[diesel.nvim] " .. message, level or vim.log.levels.INFO)
end

local function git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
  return result.code == 0, (result.stdout or "") .. (result.stderr or "")
end

function M.server_installed()
  return vim.fn.filereadable(config.server_script()) == 1
end

--- Clones the language server. It is dependency-free Node, so a clone is the
--- whole install - there is nothing to build and no npm step.
---@param opts? { silent?: boolean }
---@return boolean ok
function M.install_server(opts)
  opts = opts or {}
  if config.options.lsp.path then
    if M.server_installed() then return true end
    if not opts.silent then
      notify("lsp.path is set but " .. config.server_script() .. " is missing", vim.log.levels.ERROR)
    end
    return false
  end
  if M.server_installed() then return true end
  if vim.fn.executable "git" == 0 then
    if not opts.silent then notify("git is not on PATH, cannot install the server", vim.log.levels.ERROR) end
    return false
  end

  local dir = config.server_dir()
  vim.fn.mkdir(vim.fs.dirname(dir), "p")
  if not opts.silent then notify("cloning " .. config.options.lsp.url .. " ...") end
  local ok, output = git {
    "clone",
    "--depth=1",
    "--branch",
    config.options.lsp.branch,
    config.options.lsp.url,
    dir,
  }
  if not ok then
    notify("clone failed:\n" .. output, vim.log.levels.ERROR)
    return false
  end
  if not M.server_installed() then
    notify("clone succeeded but " .. config.server_script() .. " is missing", vim.log.levels.ERROR)
    return false
  end
  if not opts.silent then notify "language server installed" end
  return true
end

--- Pulls the server clone, and reinstalls the tree-sitter parser so the two
--- stay in step.
function M.update()
  if config.options.lsp.path then
    notify("lsp.path is set; update that checkout yourself", vim.log.levels.WARN)
  elseif M.server_installed() then
    local ok, output = git({ "pull", "--ff-only" }, config.server_dir())
    notify(ok and ("server updated\n" .. vim.trim(output)) or ("server update failed:\n" .. output),
      ok and vim.log.levels.INFO or vim.log.levels.ERROR)
  else
    M.install_server()
  end

  if config.options.treesitter.enable and pcall(require, "nvim-treesitter") then
    vim.cmd "TSUpdate diesel"
  end

  for _, client in ipairs(vim.lsp.get_clients { name = "diesel" }) do
    client:stop()
  end
end

function M.info()
  local lines = {
    "diesel.nvim",
    "  server:  " .. config.server_dir() .. (M.server_installed() and "  (installed)" or "  (missing)"),
    "  grammar: " .. config.grammar_source(),
    "  node:    " .. (vim.fn.executable "node" == 1 and vim.fn.exepath "node" or "not found"),
  }
  local parser = vim.api.nvim_get_runtime_file("parser/diesel.so", false)[1]
  lines[#lines + 1] = "  parser:  " .. (parser or "not compiled yet")
  notify(table.concat(lines, "\n"))
end

return M
