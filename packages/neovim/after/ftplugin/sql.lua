local set = vim.opt_local
local keymap = vim.keymap.set

keymap('n', '<localleader>x', "<cmd>:%DB<cr>", { buffer = true, silent = true })
keymap('v', '<localleader>x', ":DB<cr>", { buffer = true, silent = true })

set.commentstring = "-- %s"
set.tabstop = 2
set.shiftwidth = 2
