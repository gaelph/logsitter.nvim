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

---Checks declare node types the plugin can handle,
-- and where to place the log line
-- ## Properties
-- `name: string`
--        A name for the Check, for debug and clarity,
-- `test: (node: treesitter_node, type: string) => boolean`
--		  The first param is the treesitter node under the cursor,
--		  the second is its type.
--        Returns `true` if the node/type should be handled by the `handle` function
-- `handle: (node: treesitter_node, type: string) => treesitter_node, string`
--        The first param is the treesitter node under the cursor,
--        the second is its type.
--        Returns the node around which the log statement should be placed, and a string --        indicating where to place it (above, below, inside)
--        If there is no placement possible, should return `nil, nil`
M.checks = {
	{
		name = "function_call",
		---
		-- @table node
		-- @string type
		-- @treturn boolean
		test = function(_, type)
			return type == "call_expression"
		end,
		---
		-- @table node
		-- @string type
		-- @treturn table, string
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
		test = function(_, type)
			return type == "formal_parameters"
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
			return strings.ends_with(type, "declaration")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "assign",
		test = function(_, type)
			return type == "assignement_expression"
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
			return consequence, constants.PLACEMENT_INSIDE
		end,
	},
	{
		name = "for, while, do, catch",
		test = function(_, type)
			return type == "for_statement"
				or type == "while_statement"
				or type == "do_statement"
				or type == "catch_clause"
		end,
		handle = function(node, _)
			local body = first(node:field("body"))
			return body, constants.PLACEMENT_INSIDE
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
		name = "statement",
		test = function(_, type)
			return strings.ends_with(type, "statement")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
}

---Expand 'expands' the selection of nodes under the
-- cursor in order to have something more meaningfull
-- to log.
-- For instance, if the cursor is on a function_call statement,
-- the node under the cursor is likely not the call_expression, but
-- member_expression, or some getter expression.
-- `expand()` should reture the function_call node to log the
-- result of the call instead of the function.
function M.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "member_expression" then
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

function M.find_function_name(node)
	local parent = node:parent()

	while parent ~= nil do
		if parent:type() == "function_declaration" then
			return parent:field("name"):text()
		elseif parent:type() == "arrow_function" then
			local gp = parent:parent()
			return gp:field("name"):text()
		end

		parent = parent:parent()
	end

	return "top_level"
end

---Inserts the text
-- @string text The stringified (expanded) node under the cursor
-- @table  position The current cursor position
function M.log(text, position)
	local label = text:gsub('"', '\\"')
	local filepath = vim.fn.expand("%:.")
	local line = position[1]

	return string.format([[oconsole.log("LS -> %s:%s -> %s: ", %s)]], filepath, line, label, text)
end

return M
