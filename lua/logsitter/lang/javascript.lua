local M = {}

local strings = require('logsitter.utils')
local constants = require('logsitter.constants')

local function first(tbl)
    local i = 0
    while tbl[i] == nil do i = i + 1 end

    return tbl[i]
end

M.checks = {
    {
        name = "function_call",
        test = function(_, type)
            return type == 'call_expression'
        end,
        handle = function(node, _)
            local grand_parent = node:parent()

            if grand_parent == nil then return node, constants.PLACEMENT_BELOW end

            local gp_type = grand_parent:type()

            if gp_type == 'statement_block' or gp_type == 'function_definition' then
                return node, constants.PLACEMENT_BELOW
            end

            if gp_type == 'return_statement' then return node, constants.PLACEMENT_ABOVE end

            return nil, nil
        end
    }, {
        name = "parameter",
        test = function(_, type)
            return type == "formal_parameters"
        end,
        handle = function(node, _)
            return node, constants.PLACEMENT_BELOW
        end
    }, {
        name = "return",
        test = function(_, type)
            return type == "return_statement"
        end,
        handle = function(node, _)
            return node, constants.PLACEMENT_ABOVE
        end
    }, {
        name = "declaration",
        test = function(_, type)
            return strings.ends_with(type, "declaration")
        end,
        handle = function(node, _)
            return node, constants.PLACEMENT_BELOW
        end
    }, {
        name = "assign",
        test = function(_, type)
            return type == 'assignement_expression'
        end,
        handle = function(node, _)
            return node, constants.PLACEMENT_BELOW
        end
    }, {
        name = "if",
        test = function(_, type)
            return type == "if_statement"
        end,
        handle = function(node, _)
            local consequence = first(node:field("consequence"))
            return consequence, constants.PLACEMENT_INSIDE
        end
    }, {
        name = "for, while, do",
        test = function(_, type)
            return type == "for_statement" or type == "while_statement" or type == "do_statement"
        end,
        handle = function(node, _)
            local body = first(node:field("body"))
            return body, constants.PLACEMENT_INSIDE
        end
    }, {
        name = "statement",
        test = function(_, type)
            return strings.ends_with(type, 'statement')
        end,
        handle = function(node, _)
            return node, constants.PLACEMENT_BELOW
        end
    }
}

function M.expand(node)
    local parent = node:parent()

    if parent ~= nil then
        local type = parent:type()

        if type == 'member_expression' then

            local gp = parent:parent()

            if gp:type() == 'call_expression' then return gp end

            return parent
        end

        if type == 'call_expression' then return parent end
    end

    return node
end

function M.log(text)
    local label = text:gsub('"', '\\"')
    return [[oconsole.log("]] .. label .. [[: ", ]] .. text .. ")"
end

return M

