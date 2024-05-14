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

---@param position Position
---@param winnr number
---@param options LogsitterOptions
---@return string
function M.get_current_file_path(position, winnr, options)
	local filepath = vim.fn.expand("%:.")

	if options.path_format == "short" then
		filepath = M.shortenpath(vim.fn.expand("%:p:h"), winnr)
	elseif options.path_format == "fileonly" then
		filepath = vim.fn.expand("%:p:t")
	end

	local line = position[1]

	return string.format("%s:%d", filepath, line)
end

function M.get_log_function(options, default)
	local ft = vim.api.nvim_buf_get_option(0, "filetype")
	local log_function = default

	if options.logging_functions[ft] ~= nil then
		log_function = options.logging_functions[ft]
	end

	return log_function
end

return M
