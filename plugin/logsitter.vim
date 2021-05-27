if !has('nvim-0.5')
  echoerr "logsitter.nvim requires at least nvim-0.5. Please update or uninstall"
  finish
end

if exists('g:loaded_logsitter')
  finish
endif
let g:loaded_logsitter = 1

command! -nargs=*  Logsitter lua require('logsitter').log(<f-args>)
