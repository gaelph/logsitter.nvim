local M = {}

---Returns the first non-nil value indexed by a number in a table.
---Handles tables that start at index 0 or 1.
---@generic T
---@param tbl T[]
---@return T|nil
function M.first(tbl)
	-- Standard case: index starts at 1
	if tbl[1] ~= nil then
		return tbl[1]
	end

	-- Alternative case: index starts at 0
	if tbl[0] ~= nil then
		return tbl[0]
	end

	-- Fallback: search for the first numeric element
	-- (for edge cases where index starts elsewhere)
	for i = 0, #tbl do
		if tbl[i] ~= nil then
			return tbl[i]
		end
	end

	-- No element found
	return nil
end

---Shorthand for replace_termcodes
---@param str string
---@return string
function M.rtc(str)
	return vim.api.nvim_replace_termcodes(str, true, false, true)
end

---Escapes special characters in a string for safe inclusion in log statements
---@param str string  The string to escape
---@return string  The escaped string
function M.escape_string(str)
	return str
		:gsub('\\', '\\\\')  -- Backslashes FIRST (important!)
		:gsub('"', '\\"')     -- Double quotes
		:gsub('\n', '\\n')    -- Newlines
		:gsub('\r', '\\r')    -- Carriage returns
		:gsub('\t', '\\t')    -- Tabs
end

-- Makes node text fit on one line
---@param node TSNode
---@return string
function M.node_text(node)
	return vim.treesitter.get_node_text(node, 0)
end

---@param filepath string
---@param winnr number
---@return string
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

---Gets the log function for the current filetype
---@param options LogsitterOptions
---@param default string  Default log function name
---@return string  The log function to use
function M.get_log_function(options, default)
	-- Use modern vim.bo API instead of deprecated nvim_buf_get_option
	local ft = vim.bo[0].filetype
	local log_function = default

	if options.logging_functions and options.logging_functions[ft] ~= nil then
		log_function = options.logging_functions[ft]
	end

	return log_function
end

return M
