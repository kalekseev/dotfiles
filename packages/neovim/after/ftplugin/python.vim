set tw=78 ts=4 sw=4 sta et sts=4 ai

" Wrap at 72 chars for comments.
set formatoptions=cq textwidth=72 foldignore= wildignore+=*.py[co]

set colorcolumn=110
" Execute a selection of code
python3 << EOL
import vim
import textwrap
def EvaluateCurrentRange():
    eval(compile(textwrap.dedent('\n'.join(vim.current.range)),'','exec'),globals())
EOL

vnoremap <silent> <buffer> <F5> :py3 EvaluateCurrentRange()<CR>
nnoremap <silent> <buffer> <F7> :call BreakpointToggle(line('.'), "breakpoint()  # XXX BREAKPOINT")<CR>
