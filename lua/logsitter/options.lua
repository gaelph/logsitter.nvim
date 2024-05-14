---@class LogsitterOptions
---@field path_format "default" | "short" | "fileonly"		Display shortened paths (default: false)
---@field prefix string						Prefix for log messages (default: "[LS] ->")
---@field separator string				Separator for log messages (default: "->")
---@field logging_functions table<string, string>
local DefaultOptions = {
	path_format = "default",
	prefix = "[LS] ->",
	separator = "->",
	logging_functions = {
		javascript = "console.log",
		javascriptreact = "console.log",
		typescript = "console.log",
		typescriptreact = "console.log",
		lua = "print",
		go = "log.Printf",
		python = "print",
		swift = "print",
	},
}

return DefaultOptions
