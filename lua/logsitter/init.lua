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
local tsutils = require('nvim-treesitter.ts_utils')

local constants = require('plugins.logsitter.constants')
local u = require('plugins.logsitter.utils')

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
        print("found a ".. c.name)
        r, placement = c.handle(parent, type)

        if r ~= nil then
          return r, placement
        end
      end
    end

    parent = parent:parent()
  end
end

-- returns the proper logger for a given format
local function get_logger(ft)
  return require('plugins.logsitter.lang.'..ft)
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

  return {line, col}
end

local M = {}

function M.log(filetype)
  local logger = get_logger(filetype)
  if logger == nil then return end

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
  vim.api.nvim_feedkeys(output, 'n', true)
end

return M
