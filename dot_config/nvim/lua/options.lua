-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true
vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 8

vim.cmd [[
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) | execute 'cd '.argv()[0] | endif
]]

-- Set the width of a tab character to 4 spaces
vim.opt.tabstop = 4

-- Set the number of spaces inserted or removed when pressing Tab or Backspace
vim.opt.softtabstop = 4

-- Set the number of spaces used for indentation
vim.opt.shiftwidth = 4

-- Convert tab characters to spaces
vim.opt.expandtab = true

-- Enable smart indentation based on code structure
vim.opt.smartindent = true

-- Disable line wrapping
vim.opt.wrap = false

-- Disable swap file creation
vim.opt.swapfile = false

-- Disable backup file creation
vim.opt.backup = false

-- Enable 24-bit color support in the terminal
vim.opt.termguicolors = true

-- Reduce the time before writing swap files and triggering CursorHold event (50ms)
vim.opt.updatetime = 50

-- Highlight column 80 as a guide for code formatting
vim.opt.colorcolumn = '80'

-- vim: ts=2 sts=2 sw=2 et
