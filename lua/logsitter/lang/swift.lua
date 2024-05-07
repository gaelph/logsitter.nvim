---@meta
require("logsitter.types.logger")

---@class SwiftLogger : Logger
---@field log fun(text:string, insert_pos:Position, winnr:number)  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.
local SwiftLogger = {}

local u = require("logsitter.utils")
local constants = require("logsitter.constants")

SwiftLogger.checks = {
	{
		name = "function_call",
		test = function(_, type)
			return type == "call_expression"
		end,
		handle = function(node, _)
			local grand_parent = node:parent()

			if grand_parent == nil then
				return node, constants.PLACEMENT_BELOW
			end

			local gp_type = grand_parent:type()

			if gp_type == "statements" or gp_type == "function_declaration" then
				return node, constants.PLACEMENT_BELOW
			end

			if gp_type == "control_transfert_statement" then
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

			return type == "simple_identifier"
				and vim.tbl_contains({
					"lambda_parameter",
					"parameter",
				}, parent_type)
		end,
		handle = function(node, _)
			local parameters = node:parent()
			if parameters == nil then
				return node, constants.PLACEMENT_BELOW
			end

			local function_declaration = parameters:parent()
			if function_declaration == nil then
				return node, constants.PLACEMENT_BELOW
			end

			local statements = nil
			for child, _ in function_declaration:iter_children() do
				if child:type() == "statements" then
					statements = child
					break
				end
			end
			return statements, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "return",
		test = function(_, type)
			return type == "control_transfert_statement"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "closure",
		test = function(_, type)
			return type == "lambda_literal"
		end,
		handle = function(node, _)
			local statements = nil
			for child, _ in node:iter_children() do
				if child:type() == "statements" then
					statements = child
					break
				end
			end

			return statements, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "declaration",
		test = function(_, type)
			return vim.endswidth(type, "declaration")
		end,
		handle = function(node, _)
			if node:type() == "function_declaration" then
				local body = u.first(node:field("body"))
				return body, constants.PLACEMENT_INSIDE
			end

			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "assign",
		test = function(_, type)
			return type == "assignment"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "guard",
		test = function(_, type)
			return type == "guard_statement"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "if",
		test = function(_, type)
			return type == "if_statement"
		end,
		handle = function(node, _)
			local statements = nil
			for child, _ in node:iter_children() do
				if child:type() == "statements" then
					statements = child
					break
				end
			end

			return statements, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "for, while, do",
		test = function(_, type)
			return type == "for_statement" or type == "while_statement" or type == "do_statement"
		end,
		handle = function(node, _)
			local statements = nil
			for child, _ in node:iter_children() do
				if child:type() == "statements" then
					statements = child
					break
				end
			end
			return statements, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "switch",
		test = function(_, type)
			return type == "switch_statement"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "case",
		test = function(_, type)
			return type == "switch_pattern"
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "statement",
		test = function(_, type)
			return vim.endswidth(type, "statement")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
}

function SwiftLogger.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "navigation_suffix" then
			parent = parent:parent()
			type = parent:type()
		end

		if type == "navigation_expression" then
			local gp = parent:parent()

			if gp:type() == "call_expression" then
				return gp
			end

			return parent
		end

		if type == "call_expression" then
			return parent
		end
	end

	return node
end

function SwiftLogger.log(text, _)
	local label = text:gsub('"', '\\"')

	return string.format([[oprint("LS -> \(#file):\(#line) -> %s: \(%s)")]], label, text)
end

return SwiftLogger
