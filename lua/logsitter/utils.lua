local tsutils = require('nvim-treesitter.ts_utils')

local M = {}

-- Shorthand for replace_termcodes
function M.rtc (str)
  return vim.api.nvim_replace_termcodes(str, true, false, true)
end

-- Makes node text fit on one line
function M.node_text(node)
  return table.concat(tsutils.get_node_text(node), ', ')
end

return M

