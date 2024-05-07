
---@class Logger
---@field log fun(text:string, insert_pos:Position, winnr:number)  Adds a log statement to the buffer.
---@field expand fun(node:TSNode): TSNode		Expands the node to have something meaning full to print.
---@field checks Check[]		List of checks to run on the node to decide where to place the log statement.

---@class Check
---@field name string 																			 A unique name for this check.	Only useful for debugging.
---@field test fun(node:TSNode, type:string): boolean      Return true if the node should be handle, false otherwise.
---@field handle fun(node:TSNode, type:string): TSNode|nil, Placement  Returns where the log statement should be inserted.

---@alias Position [number, number] 	Line and column number.

---@alias Placement "above" | "below" | "inside" | nil  Where the log statement should be inserted.
