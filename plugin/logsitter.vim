if !has('nvim-0.5')
  echoerr "logsitter.nvim requires at least nvim-0.5. Please update or uninstall"
  finish
end

if exists('g:loaded_logsitter')
  finish
endif
let g:loaded_logsitter = 1

command! Logsitter lua require('logsitter').log()
command! -range LogsitterV lua require('logsitter').log_visual()

command! LogsitterClearBuf lua require('logsitter').clear_buf()
command! LogsitterClearAll lua require('logsitter').clear_all()
