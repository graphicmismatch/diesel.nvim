-- Filetype detection works even if setup() is never called (or has not run
-- yet), so `nvim song.dsl` is a diesel buffer from the first redraw.
vim.filetype.add { extension = { dsl = "diesel" } }
