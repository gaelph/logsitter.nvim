---@meta
require("logsitter.types.logger")

---@class JavascriptLogger : Logger
---@field log fun(text:string, filelocation:string, options:LogsitterOptions): string  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.
local JavascriptLogger = {}

local u = require("logsitter.utils")
local constants = require("logsitter.constants")

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
---@type Check[]
JavascriptLogger.checks = {
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

			if gp_type == "statement_block" or gp_type == "function_definition" or gp_type == "method_definition" then
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
			return vim.endswith(type, "_parameter")
		end,
		handle = function(node, _)
			local parent = node:parent():parent()
			if vim.tbl_contains({
				"function_definition",
				"method_definition",
			}, parent:type()) then
				local body = u.first(parent:field("body"))
				return body, constants.PLACEMENT_INSIDE
			end
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
			return vim.endswith(type, "declaration")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
	{
		name = "assign",
		test = function(_, type)
			return type == "assignment_expression"
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
			local body = u.first(node:field("body"))
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
			return vim.endswith(type, "statement")
		end,
		handle = function(node, _)
			return node, constants.PLACEMENT_BELOW
		end,
	},
}

---Expand 'expands' the selection of nodes under the
-- cursor in order to have something more meaningful
-- to log.
-- For instance, if the cursor is on a function_call statement,
-- the node under the cursor is likely not the call_expression, but
-- member_expression, or some getter expression.
-- `expand()` should return the function_call node to log the
-- result of the call instead of the function.
---@param node TSNode
---@return TSNode
function JavascriptLogger.expand(node)
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

---Inserts the text
---@param text string  The stringified (expanded) node under the cursor
---@param filelocation string
---@param options LogsitterOptions  The options passed to the logger
---@return string  The text to insert in the buffer
function JavascriptLogger.log(text, filelocation, options)
	local label = u.escape_string(text)

	return string.format(
		'o%s("%s %s %s %s: ", %s)',
		u.get_log_function(options, "console.log"),
		options.prefix,
		filelocation,
		options.separator,
		label,
		text
	)
end

return JavascriptLogger
