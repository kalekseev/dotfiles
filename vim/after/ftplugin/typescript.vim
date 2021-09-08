nnoremap gd :TSDef<CR>
nnoremap <leader>d :TSDefPreview<CR>
nnoremap K :TSDoc<CR>
nnoremap <silent> <buffer> <F7> :call BreakpointToggle(line('.'), "debugger;")<CR>
