if vim.g.loaded_diesel then return end
vim.g.loaded_diesel = true

vim.api.nvim_create_user_command("DieselInstall", function() require("diesel").install() end, {
  desc = "Clone the Diesel language server",
})

vim.api.nvim_create_user_command("DieselUpdate", function() require("diesel").update() end, {
  desc = "Update the Diesel language server and tree-sitter parser",
})

vim.api.nvim_create_user_command("DieselInfo", function() require("diesel").info() end, {
  desc = "Show where diesel.nvim's server and parser live",
})
