if has('vim_starting')
    set encoding=utf-8
    scriptencoding utf-8
endif

" reset my autocmd group
augroup MyAutoCmd
    autocmd!
augroup END


"* * * * * * * * * * * * * * * * * SETUP * * * * * * * * * * * * * * * * * * *
" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

" remap leader
let g:mapleader = "\<Space>"
let g:maplocalleader = "\<Space>"
nnoremap <Space> <Nop>

" russian keymap
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz,№;#

" indent settings
set shiftwidth=4
set softtabstop=4
set shiftround
set expandtab
set autoindent

" make cmdline tab completion similar to bash
set wildmode=longest,list,full

" enable ctrl-n and ctrl-p to scroll thru matches
set wildmenu
set wildignore=*.module.scss.d.ts,*.aux,*.log,*.class,*.o,*.obj,*~,.git,*.pyc,*/.hg/*

" don't continue comments when pushing o/O
set formatoptions-=o

" vertical/horizontal scroll off settings
set scrolloff=3
set sidescrolloff=7
set sidescroll=1

" some stuff to get the mouse going in term
set mouse=n

" split to right
set splitright
set splitbelow

" reload when files modified outside of vim
" set autoread


" yank use system clipboard
set clipboard=unnamed

" ignore case only if contains upper case
set ignorecase
set smartcase

" incremental search
set incsearch

" match highlight
set hlsearch

" search from the top at the end
set wrapscan

" don't redraw while macro execution
set lazyredraw

" theme
set background=dark
set termguicolors
set colorcolumn=80

"* * * * * * * * * * * * * * * * * MAPPING * * * * * * * * * * * * * * * * * *
" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

" edit vimrc
" nnoremap <Leader>ev :<C-u>edit ~/dotfiles/nixpkgs/vimrc<CR>

" imap jj <Esc>

" switch between two files
map <Leader><Leader> <C-^>

" use arrow keys for windows size change
map <Up> <C-W>+
map <Down> <C-W>-
map <Left> <C-W><
map <Right> <C-W>>

" make <c-m> clear the highlight as well as redraw
nmap <leader>m :nohls<CR>

" map Q to something useful
map Q gq

command! -bang Q q<bang>
command! -bang QA q<bang>
command! -bang Qa q<bang>

" make Y consistent with C and D
nmap Y y$

" key mapping for saving file
inoremap <C-s> <Esc>:w<CR>
nnoremap <C-s> :w<CR>

" write with sudo
cmap w!! %!sudo tee > /dev/null %

" remove trailing whitespace
nmap <leader>tr :%s/\s\+$<CR>

" indent
xmap < <gV
xmap > >gV

" reselect pasted text
nmap <Leader>v V`]

" move selected lines
vnoremap <C-j> :m'>+<CR>gv=gv
vnoremap <C-k> :m-2<CR>gv=gv
vnoremap <C-h> <gv
vnoremap <C-l> >gv

" allow the . to execute once for each line of a visual selection
vnoremap . :normal .<CR>

command! CountSearch execute '%s///gn'
command! CopyFilename execute 'let @+=expand("%:t")'
command! CopyFilepath execute 'let @+=expand("%:p")'
command! -range ApplyQMacros execute '<line1>,<line2>normal! @q'


"* * * * * * * * * * * * * * * * * PLUGINS * * * * * * * * * * * * * * * * * *
" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

"nvim-tree-lua
nmap <silent> <C-f> :NvimTreeFindFile<CR>

"vim-argwrap
nnoremap <silent>gW :<C-u>:ArgWrap<CR>

" CamelCaseMotion
"==============================================================================
nmap <silent> W <Plug>CamelCaseMotion_w
xmap <silent> W <Plug>CamelCaseMotion_w
omap <silent> W <Plug>CamelCaseMotion_w
nmap <silent> B <Plug>CamelCaseMotion_b
xmap <silent> B <Plug>CamelCaseMotion_b
omap <silent> B <Plug>CamelCaseMotion_b

"==============================================================================
nmap <Space>/ gcc
vmap <Space>/ gc


" vim-niceblock
"==============================================================================
xmap I <Plug>(niceblock-I)
xmap A <Plug>(niceblock-A)


" git and diff
"==============================================================================
autocmd MyAutoCmd BufReadPost fugitive://* set bufhidden=delete
command! -bang -nargs=+ Sgrep execute 'silent Ggrep<bang> <args>' | copen
map <Leader>1 :diffget LOCAL<CR>
map <Leader>2 :diffget BASE<CR>
map <Leader>3 :diffget REMOTE<CR>
set diffopt+=internal,algorithm:patience


" telescope
nmap <leader>f :<C-U>Telescope live_grep theme=get_dropdown<CR>
nmap <leader>a :<C-U>Telescope grep_string theme=get_dropdown<CR>
nmap <leader>l :<C-U>Telescope oldfiles theme=get_dropdown<CR>
nmap <C-p> :<C-U>Telescope find_files theme=get_dropdown<CR>

" indentline
"==============================================================================
let g:indentLine_setConceal = 0
let g:indentLine_char = '┊'
let g:indentLine_color_term = 8
let g:indentLine_noConcealCursor=""
let g:indentLine_faster = 1


" rooter
let g:rooter_cd_cmd = "lcs"
" let g:rooter_silent_chdir = 1
let g:rooter_manual_only = 1

" direnv
let g:direnv_silent_load = 1

" test
let test#python#runner = 'pytest'
let test#strategy = "asyncrun_background"
" let g:test#preserve_screen = 1
let test#neovim#term_position = "vert"

nmap <silent> <leader>tt :TestNearest<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>ts :TestSuite<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>tg :TestVisit<CR>
nmap <silent> <leader>tT :autocmd BufWritePost * TestNearest<CR>
nmap <silent> <leader>tF :autocmd BufWritePost * TestFile<CR>
nmap <silent> <leader>tq :autocmd! BufWritePost *<CR>

"* * * * * * * * * * * * * * * * * EXTRA * * * * * * * * * * * * * * * * * * *
" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

" filetype specific settings
autocmd MyAutoCmd FileType html setlocal ts=2 sw=2 sta et sts=2 ai
autocmd MyAutoCmd FileType vue setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType json setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType typescriptreact setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110

" save on focus lost
autocmd MyAutoCmd FocusLost * :silent! wall

" don't show trailing spaces in insert mode
autocmd MyAutoCmd InsertEnter * :set listchars-=trail:·
autocmd MyAutoCmd InsertLeave * :set listchars+=trail:·

" js, jsx
autocmd MyAutoCmd BufRead,BufNewFile *.js call s:FTjs()

" django
autocmd MyAutoCmd BufRead,BufNewFile */backend/*/templates/*.html set filetype=htmldjango

" jump to last cursor position when opening a file
" don't do it when writing a commit log entry
autocmd MyAutoCmd BufReadPost * call SetCursorPosition()


function! SetCursorPosition()
    if &filetype !~ 'commit\c'
        if line("'\"") > 0 && line("'\"") <= line("$")
            exe "normal! g`\""
            normal! zz
        endif
    end
endfunction

function! BreakpointToggle(lnum, cmd)
    let line = getline(a:lnum)
    let plnum = prevnonblank(a:lnum)
    call append(line('.')-1, repeat(' ', indent(plnum)).a:cmd)
    normal k
    if &modifiable && &modified | write | endif
endfunction

nnoremap <leader>uu :call GenUUID()<CR>
func! GenUUID()
  let cmd = 'uuidgen | tr "[:upper:]" "[:lower:]" | tr -d "[:cntrl:]"'
  silent exec ":normal a" . system(cmd)
endfunc


" Distinguish between javascript, jsx
func! s:FTjs()
  let n = 1
  while n < 10 && n < line("$")
    if getline(n) =~ "\\v'react'|'preact'"
      set filetype=javascript.jsx
      return
    endif
    let n = n + 1
  endwhile
endfunc


" windows
nnoremap <c-w>z <C-W>\| <C-W>_

let g:db_ui_env_variable_url = 'DATABASE_URL'

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!
