---@meta
require("logsitter.types.logger")

---@class LuaLogger : Logger
---@field log fun(text:string, insert_pos:Position, winnr:number)  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.
local LuaLogger = {}

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
		name = "if, for, while",
		test = function(_, type)
			return type == "condition_expression"
		end,
		handle = function(node, _)
			local parent = node:parent()
			if parent ~= nil then
				local first_child = parent:child(1)
				return first_child, constants.PLACEMENT_INSIDE
			end
			return node
		end,
	},
}

---@param node TSNode
---@return TSNode
function LuaLogger.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "function_call" or type == "field_expression" then
			return parent
		end
		print("type: " .. type)
	end

	return node
end

---@param text string
-- @param position number
-- @param winnr number
---@return string
function LuaLogger.log(text, _, _)
	local label = text:gsub('"', '\\"')

	return string.format([[oprint("[LS] %s: " .. vim.inspect(%s))]], label, text)
end

return LuaLogger
