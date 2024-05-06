local M = {}

local strings = require("logsitter.utils")
local constants = require("logsitter.constants")

local function first(tbl)
	local i = 0
	while tbl[i] == nil do
		i = i + 1
	end

	return tbl[i]
end

M.checks = {
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
			return strings.ends_with(type, "definition")
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
			local consequence = first(node:field("consequence"))
			return consequence, constants.PLACEMENT_ABOVE
		end,
	},
	{
		name = "for, while, do",
		test = function(_, type)
			return type == "for_statement" or type == "while_statement" or type == "do_statement"
		end,
		handle = function(node, _)
			local body = first(node:field("body"))
			return body, constants.PLACEMENT_ABOVE
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

---Inserts the text
-- @string text The stringified (expanded) node under the cursor
-- @table  position The current cursor position
function M.log(text, position)
	local label = text:gsub('"', '\\"')
	local filepath = vim.fn.expand("%:.")
	local line = position[1]

	return string.format([[oprint(f'LS -> %s:%s -> %s: {%s}\n')]], filepath, line, label, text)
end

return M
