---@meta
require("logsitter.types.logger")

---@class PythonLogger : Logger
---@field log fun(text:string, insert_pos:Position, winnr:number)  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.
local PythonLogger = {}

local u = require("logsitter.utils")
local constants = require("logsitter.constants")

PythonLogger.checks = {
	{
		name = "function_call",
		test = function(_, type)
			return type == "call"
		end,
		handle = function(node, _)
			local grand_parent = node:parent()

			if grand_parent == nil then
				return node, constants.PLACEMENT_BELOW
			end

			local gp_type = grand_parent:type()

			if gp_type == "block" or gp_type == "function_definition" then
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
			local parent_type = parent:type()
			return vim.tbl_contains({
				"typed_parameter",
				"parameters",
			}, parent_type)
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "return",
		test = function(_, type)
			return type == "return_statement"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "declaration",
		test = function(_, type)
			return vim.endswith(type, "definition")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "assign",
		test = function(_, type)
			return type == "assignement"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "if",
		test = function(_, type)
			return type == "if_statement"
		end,
		handle = function(node, _)
			local consequence = u.first(node:field("consequence"))
			return consequence, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "for, while, do",
		test = function(_, type)
			return type == "for_statement" or type == "while_statement" or type == "do_statement"
		end,
		handle = function(node, _)
			local body = u.first(node:field("body"))
			return body, constants.PLACEMENT_ABOVE
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

function PythonLogger.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "selector_expression" then
			local gp = parent:parent()

			if gp:type() == "call" then
				return gp
			end

			return parent
		end

		if type == "call" then
			return parent
		end
	end

	return node
end

function PythonLogger.log(text, position)
	local label = text:gsub('"', '\\"')
	local filepath = vim.fn.expand("%:.")
	local line = position[1]

	return string.format([[oprint(f'LS -> %s:%s -> %s: {%s}\n')]], filepath, line, label, text)
end

return PythonLogger
