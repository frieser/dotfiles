-- collapse next line into one line
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join the next line without moving the cursor' })

-- scroll and center
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center the cursor' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center the cursor' })

-- next item in find and center
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Go to next search result and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Go to previous search result and center' })

-- paste without losing the copied text
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Paste without overwriting the clipboard' })

-- next greatest remap ever : asbjornHaland
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Copy selection to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Copy line to system clipboard' })

-- delete without losing the copied text
vim.keymap.set('n', '<leader>d', '"_d', { desc = 'Delete without overwriting the clipboard' })
vim.keymap.set('v', '<leader>d', '"_d', { desc = 'Delete selection without overwriting the clipboard' })

-- disable Ex mode
vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex mode' })

-- navigate quickfix list and location list and center
vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz', { desc = 'Go to next quickfix item and center' })
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz', { desc = 'Go to previous quickfix item and center' })
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz', { desc = 'Go to next location list item and center' })
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz', { desc = 'Go to previous location list item and center' })

-- search and replace the word under cursor
vim.keymap.set('n', '<leader>s', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>', { desc = 'Search and replace the word under cursor' })

-- make file executable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Make the current file executable' })
