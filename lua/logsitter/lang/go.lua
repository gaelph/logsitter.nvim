---@meta
require("logsitter.types.logger")

---@class GoLogger : Logger
---@field checks Check[]
---@field log fun(text:string, filelocation:string, options: LogsitterOptions): string
---@field expand fun(node:TSNode): TSNode
local GoLogger = {}

local u = require("logsitter.utils")
local constants = require("logsitter.constants")

GoLogger.checks = {
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

			if gp_type == "block" or gp_type == "function_declaration" then
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
		name = "for, while, do",
		test = function(_, type)
			return type == "for_statement" or type == "while_statement" or type == "do_statement"
		end,
		handle = function(node, _)
			local body = u.first(node:field("body"))
			return body, constants.PLACEMENT_INSIDE
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

---Expands the given node the its parent so there is some thing meaning full to log.
---@param node TSNode
---@return TSNode
function GoLogger.expand(node)
	local parent = node:parent()

	if parent ~= nil then
		local type = parent:type()

		if type == "selector_expression" then
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

---Renders the log message for the given text and position.
---@param text string
---@param filelocation string
---@param options LogsitterOptions
---@return string
function GoLogger.log(text, filelocation, options)
	local label = u.escape_string(text)

	return string.format(
		[[o%s("%s %s %s %s: %%+v\n", %s)]],
		u.get_log_function(options, "log.Printf"),
		options.prefix,
		filelocation,
		options.separator,
		label,
		text
	)
end

return GoLogger
