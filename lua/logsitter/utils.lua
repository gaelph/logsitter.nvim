local M = {}

-- Shorthand for replace_termcodes
function M.rtc(str)
	return vim.api.nvim_replace_termcodes(str, true, false, true)
end

-- Makes node text fit on one line
function M.node_text(node)
	return table.concat(vim.treesitter.query.get_node_text(node), ", ")
end

--- Return `true` if `str` starts with `start`
-- @string str
-- @string start
-- @return a boolean value
function M.starts_with(str, start)
	return str:sub(1, #start) == start
end

--- Return `true` if `str` ends with `start`
-- @string str
-- @string ending
-- @return a boolean value
function M.ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

return M
