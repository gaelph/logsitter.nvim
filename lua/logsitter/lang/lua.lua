---@meta
require("logsitter.types.logger")

---@class LuaLogger : Logger
---@field log fun(text:string, insert_pos:Position, winnr:number, options:LogsitterOptions): string  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.
local LuaLogger = {}

local u = require("logsitter.utils")
local constants = require("logsitter.constants")

---@type Check[]
LuaLogger.checks = {
	{
		name = "function_call",
		test = function(_, type)
			return type == "function_call"
		end,
		handle = function(node, _)
			local grand_parent = node:parent()

			if grand_parent == nil then
				return node, constants.PLACEMENT_BELOW
			end

			local gp_type = grand_parent:type()

			if gp_type == "statement_block" or gp_type == "function_definition" then
				return node, constants.PLACEMENT_BELOW
			end

			if gp_type == "return_statement" then
				return node, constants.PLACEMENT_ABOVE
			end

			return nil, nil
		end,
	},
	{
		name = "parameter",
		test = function(node, type)
			local parent = node:parent()
			return parent ~= nil and parent:type() == "parameters" and type == "identifier"
		end,
		handle = function(node, _)
			return node:parent(), constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "argument",
		test = function(node, type)
			local parent = node:parent()
			return parent ~= nil and parent:type() == "arguments"
		end,
		handle = function(node, _)
			return node:parent(), constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "return",
		test = function(node, _)
			local parent = node:parent()
			return parent ~= nil and parent:type() == "return_statement"
		end,
		handle = function(node, _)
			return node:parent(), constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "declaration",
		test = function(_, type)
			return vim.endswith(type, "declaration")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "if",
		test = function(_, type)
			return type == "if_statement" or type == "elseif_statement"
		end,
		handle = function(node, _)
			local node = u.first(node:field("consequence"))

			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "for, while",
		test = function(_, type)
			return type == "for_statement" or type == "while_statement"
		end,
		handle = function(node, _)
			local node = u.first(node:field("body"))

			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "statement",
		test = function(_, type)
			return vim.endswith(type, "statement")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
}

---@param node TSNode
---@return TSNode
function LuaLogger.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "function_call" or type == "dot_index_expression" then
			return parent
		end
	end

	return node
end

---@param text string
-- @param position number
---@param winnr number
---@param options LogsitterOptions
---@return string
function LuaLogger.log(text, position, winnr, options)
	local label = text:gsub('"', '\\"')
	local filepath = vim.fn.expand("%:.")
	local line = position[1]

	if options.path_format == "short" then
		filepath = u.shortenpath(vim.fn.expand("%:p:h"), winnr)
	elseif options.path_format == "fileonly" then
		filepath = vim.fn.expand("%:p:t")
	end

	return string.format(
		[[oprint("%s %s:%s %s %s: " .. vim.inspect(%s))]],
		options.prefix,
		filepath,
		line,
		options.separator,
		label,
		text
	)
end

return LuaLogger
