local M = {}

---Attempts at returning the first value indexed by a number in a table.
---That is to avoid string indexes, or index errors if the index starts
---neither at 0 nor at 1.
---@generic T
---@param tbl T[]
---@return T|nil
function M.first(tbl)
	local i = 0
	while tbl[i] == nil and i <= #tbl do
		i = i + 1
	end

	return tbl[i]
end

---Shorthand for replace_termcodes
---@param str string
---@return string
function M.rtc(str)
	return vim.api.nvim_replace_termcodes(str, true, false, true)
end

-- Makes node text fit on one line
---@param node TSNode
---@retusn string
function M.node_text(node)
	return vim.treesitter.get_node_text(node, 0)
end

---@param filepath string
---@param winnr number
---@retunr string
function M.shortenpath(filepath, winnr)
	local cwd = vim.fn.getcwd(winnr)
	filepath = filepath:sub(#cwd)
	filepath = vim.fs.normalize(filepath)
	local filename = vim.fn.expand("%:t")

	filepath = vim.fn.pathshorten(filepath .. "/" .. filename)

	return filepath
end

return M
