" Disable Neovim syncing for Copilot buffers
augroup CopilotBuffers
  autocmd!
  autocmd BufRead,BufEnter * if bufname('%') =~ 'copilot' | setlocal nobuflisted | endif
augroup END
