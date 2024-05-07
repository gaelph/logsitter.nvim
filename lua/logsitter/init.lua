-------------------------
-- Logsitter module
--
-- @module logsitter
--
-- @todo Handle Function Name declaration (print ”Funtion <naninana> called”)
-- @todo Handle Properties in literal object declaration
-- @todo Handle visual selection (only single line ones)
-- @todo Handle motions (no multiline)
--
local tsutils = require("nvim-treesitter.ts_utils")

local constants = require("logsitter.constants")
local u = require("logsitter.utils")

--- Finds the node after which the "log" should be inserted
-- @todo refactor to be more legible
local function parent_declaration(checks, node)
	local parent = node

	while parent ~= nil do
		local type = parent:type()
		local r = nil
		local placement = "below"

		for _, c in ipairs(checks) do
			if c.test(parent, type) then
				print("found a " .. c.name)
				r, placement = c.handle(parent, type)

				if r ~= nil then
					return r, placement
				end
			end
		end

		parent = parent:parent()
	end
end

-- returns the posistion at which the log
-- should be inserted
local function get_insertion_position(logger, node, winnr)
	local pos = vim.api.nvim_win_get_cursor(winnr)
	local decl, placement = parent_declaration(logger.checks, node)

	local line = pos[1] or 0
	local col = pos[2] or 0

	if decl ~= nil then
		if placement == constants.PLACEMENT_BELOW then
			line, col = decl:end_()
			line = line + 1
		elseif placement == constants.PLACEMENT_ABOVE then
			line, col = decl:start()
		elseif placement == constants.PLACEMENT_INSIDE then
			line, col = decl:start()

			line = line + 1
		end
	end

	return { line, col }
end

local loggers = {}
local M = {}

function M.register(logger, for_file_types)
	for _, filetype in ipairs(for_file_types) do
		loggers[filetype] = logger
	end
end

local function get_logger(filetype)
	return loggers[filetype]
end

function M.log()
	local logger = get_logger(vim.bo.filetype)
	if logger == nil then
		print("No logger for " .. vim.bo.filetype)
		return
	end

	local winnr = vim.api.nvim_get_current_win()

	local node = tsutils.get_node_at_cursor(winnr)

	if node == nil then
		vim.cmd('echoerr "No node found"')
	end

	local insert_pos = get_insertion_position(logger, node, winnr)

	local text = u.node_text(logger.expand(node))

	local output = logger.log(text, insert_pos, winnr)
	output = output .. "<esc>"
	output = u.rtc(output)

	vim.api.nvim_win_set_cursor(winnr, insert_pos)
	vim.api.nvim_feedkeys(output, "n", true)
end

function M.log_visual()
	local logger = get_logger(vim.bo.filetype)
	if logger == nil then
		print("No logger for " .. vim.bo.filetype)
		return
	end

	local output = u.rtc("<esc>")
	vim.api.nvim_feedkeys(output, "n", true)

	local start = vim.fn.getpos("'<")
	local stop = vim.fn.getpos("'>")
	local winnr = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_get_current_buf()

	local node = vim.treesitter.get_node({
		bufnr = bufnr,
		pos = { start[1], start[2] },
	})

	if node == nil then
		vim.cmd('echoerr "No node found"')
	end

	local insert_pos = get_insertion_position(logger, node, winnr)

	local s = start[2] - 1
	local e = stop[2] + 1
	local text = vim.api.nvim_buf_get_lines(bufnr, s, e, false)[1]

	if text == nil then
		print("No text selected")
		return
	end

	text = string.sub(text, start[3], stop[3])

	output = logger.log(text, insert_pos, winnr)
	output = output .. "<esc>gv"
	output = u.rtc(output)

	vim.api.nvim_win_set_cursor(winnr, insert_pos)
	vim.api.nvim_feedkeys(output, "n", true)
end

M.register(require("logsitter.lang.javascript"), {
	"javascript",
	"javascriptreact",
	"javascript.jsx",
	"typescript",
	"typescriptreact",
	"typescript.tsx",
	"vue",
	"svelte",
	"astro",
})
M.register(require("logsitter.lang.go"), { "go" })
M.register(require("logsitter.lang.lua"), { "lua" })
M.register(require("logsitter.lang.python"), { "python" })
M.register(require("logsitter.lang.swift"), { "swift" })

return M
