vim.bo.commentstring = "// %s"
vim.bo.comments = "s1:/*,mb:*,ex:*/,://"
vim.bo.suffixesadd = ".dsl"

-- Node names, port names and node types are all word-ish; `-` never appears in
-- an identifier, so leave iskeyword alone and only add what Diesel allows.
vim.opt_local.iskeyword:append "_"
