local M = {}

local strings = require("logsitter.utils")
local constants = require("logsitter.constants")

local function first(tbl)
	local i = 0
	while tbl[i] == nil and i <= #tbl do
		i = i + 1
	end

	return tbl[i]
end

M.checks = {
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
			return strings.ends_with(type, "declaration")
		end,
		handle = function(node, _)
			if node:type() == "function_declaration" then
				local body = first(node:field("body"))
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
			return strings.ends_with(type, "statement")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
}

function M.expand(node)
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

---Inserts the text
-- @string text The stringified (expanded) node under the cursor
-- @table  position The current cursor position
function M.log(text, _)
	local label = text:gsub('"', '\\"')

	return string.format([[oprint("LS -> \(#file):\(#line) -> %s: \(%s)")]], label, text)
end

return M
