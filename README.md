# Logsitter

A [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)-based, [Turbo Console Log](https://github.com/Chakroun-Anas/turbo-console-log)-inspired, lua-written, NeoVim plugin.


Makes debugging easier by automating the process of writing log messages.

## Install

With packer:
```lua
use {"gaelph/logsitter.nvim", requires = {"nvim-treesitter/nvim-treesitter"}}
```

## Supported Languages

	* Javascript/Typescript and Svelte/Vue/Astro (`console.log()`)
	* Golang (`log.Println("... %+v\n", ...)`)
	* Lua (`print()`)

Experimental support for:
	* Python (`print()`)
	* Swift (`print()`)


## Example usage

lua:
```lua
vim.api.nvim_create_augroup("LogSitter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = "Logsitter",
	pattern = "javascript,go,lua",
	callback = function()
		vim.keymap.set("n", "<localleader>lg", function()
			require("logsitter").log()
		end)

		-- experimental visual mode
		vim.keymap.set("x", "<localleader>lg", function()
			require("logsitter").log_visual()
		end)
	end,
})
```

There is also a lua function:
```lua
require("logsitter").log()
```


To use Logsitter with other file types:

```lua
-- This can go in after/ftplugin/svelte.lua
local logsitter = require("logsitter")
local javascript_logger = require("logsitter.lang.javascript")

-- tell logsitter to use the javascript_logger when the filetype is svelte
logsitter.register(javascript_logger, { "svelte" })

vim.keymap.set("n", "<localleader>lg", function()
	logsitter.log()
end)

```

## License

MIT
