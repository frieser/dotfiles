return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'

      -- You can configure highlights by doing something like:
      -- vim.cmd.hi 'Comment gui=none'
    end,
    opts = {
      on_highlights = function(highlights, colors)
        highlights['@string.go'] = { fg = colors.green2 }
        highlights['@function.go'] = { fg = colors.orange }
        highlights['@property.go'] = { fg = '#82A99C' }
        highlights['@function.method.call.go'] = { fg = '#74F2C7' }
        highlights['@keyword.conditional.go'] = { fg = colors.orange }
        highlights['@keyword.function.go'] = { fg = colors.orange }
        highlights['@keyword.return.go'] = { fg = colors.orange }
        highlights['@function.call.go'] = { fg = '#74F2C7' }
        highlights['@keyword.import.go'] = { fg = colors.orange }
        highlights['@keyword.coroutine.go'] = { fg = colors.orange }
        highlights['@keyword.go'] = { fg = colors.fg }
        highlights['@type.builtin.go'] = { fg = '#80CEB3' }
        highlights['@number.go'] = { fg = '#857777' }
        highlights['@number.float.go'] = { fg = '#857777' }
        highlights['@module.go'] = { fg = '#74F2C7' }
        highlights['@variable.parameter.go'] = { fg = '#A98282' }
      end,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
