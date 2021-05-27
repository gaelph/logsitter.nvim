# Logsitter

A [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)-based, [Turbo Console Log](https://github.com/Chakroun-Anas/turbo-console-log)-inspired, lua-written, NeoVim plugin.


Makes debugging easier by automating the process of writting log messages.

## Install

With packer:
```lua
use {"gaelph/logsitter", requires = {"nvim-treesitter/nvim-treesitter"}}
```

## Supported Languages

	* Javascript/Typescript (`console.log()`)
	* Golang (`fmt.Println("... %+v\n", ...)`)
	* Lua (`print()`)

## Example usage

VimL:
```vim
augroup Logsitter
	au!
	au  FileType javascript   nnoremap <localleader>lg :Logsitter javascript<cr>
	au  FileType go           nnoremap <localleader>lg :Logsitter go<cr>
	au  FileType lua          nnoremap <localleader>lg :Logsitter lua<cr>
augroup END
```

There is also a lua function:
```lua
require("logsitter").log(file_type)
```

## License

MIT
