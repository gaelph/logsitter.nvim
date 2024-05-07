---@class LogsitterOptions
---@field path_format "default" | "short" | "fileonly"		Display shortened paths (default: false)
---@field prefix string						Prefix for log messages (default: "[LS]")
---@field separator string				Separator for log messages (default: "->")
local DefaultOptions = {
	path_format = "default",
	prefix = "[LS] ->",
	separator = "->",
}

return DefaultOptions
