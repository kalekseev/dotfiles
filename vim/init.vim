if has('vim_starting')
    set encoding=utf-8
    scriptencoding utf-8

    if !has('nvim')
        set nocompatible
    endif
endif

" reset my autocmd group
augroup MyAutoCmd
    autocmd!
augroup END


"* * * * * * * * * * * * * * * * * SETUP * * * * * * * * * * * * * * * * * * *
" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


" turn on syntax highlighting
syntax on

" load local rc files
set exrc
set secure

" set regexpengine=1  "work faster on macos
" allow backspacing over everything in INS mode
set backspace=indent,eol,start

" store lots of :cmdline history
set history=1000

" show incomplete cmds down the bottom
set showcmd

" show current mode down the bottom
set showmode

" add line numbers
set number

" start wrapped lines with the string
set showbreak=↪..

" wrap lines
set wrap

" don't break words
set linebreak

" listchars
set list listchars=tab:»·

" add some line space for easy reading
" set linespace=4

" disable visual bell
if !has('nvim')
    set visualbell t_vb=
endif

" always show statusline
set laststatus=3

" hide buffers when not displayed
set hidden

" remap leader
let g:mapleader = "\<Space>"
let g:maplocalleader = "\<Space>"
nnoremap <Space> <Nop>

" russian keymap
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz,№;#

" turn off needless toolbar on gvim/mvim
set guioptions-=T
set guioptions-=m
" off scrollbar
set guioptions-=rL
" no guitablabel
set guioptions-=e
set guioptions+=c


" indent settings
set shiftwidth=4
set softtabstop=4
set shiftround
set expandtab
set autoindent

" fold based on indent
set foldmethod=indent

" deepest fold is 3 levels
set foldnestmax=3

" dont fold by default
set nofoldenable

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
if !has('nvim')
    set ttymouse=xterm2
endif

" BACKUP
" https://begriffs.com/posts/2019-07-19-history-use-vim.html
" Protect changes between writes. Default values of
" updatecount (200 keystrokes) and updatetime
" (4 seconds) are fine
set swapfile

set directory^=~/.vim/swap//

" protect against crash-during-write
set writebackup
" but do not persist backup after successful write
set nobackup
" use rename-and-write-new method whenever safe
set backupcopy=auto
" patch required to honor double slash at end
if has("patch-8.1.0251")
    " consolidate the writebackups -- not a big
    " deal either way, since they usually get deleted
    set backupdir^=~/.vim/backup//
end

" persist the undo tree for each file
set undofile
set undodir^=~/.vim/undo//
" END BACKUP

if has('nvim')
    set shada+=n$HOME/.vim/.viminfo.shada
else
    set viminfo+=n$HOME/.vim/.viminfo
endif

" store undo
if has('persistent_undo')
    set undodir=$HOME/.vim/undo,.
    set undofile
endif

" split to right
set splitright
set splitbelow

" reload when files modified outside of vim
set autoread

" fast terminal connection
if !has('nvim')
    set ttyfast
endif

" yank use system clipboard
set clipboard=unnamed

" ignore case only if contains upper case
set ignorecase
set smartcase
if has('nvim')
    set inccommand=nosplit
endif

" incremental search
set incsearch

" match highlight
set hlsearch

" search from the top at the end
set wrapscan

" don't redraw while macro execution
set lazyredraw

" for echodoc
set noshowmode

" theme
set background=dark
if has('nvim')
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif
if has("termguicolors")
    set termguicolors
endif


" colorscheme
let g:onedark_hide_endofbuffer = 1
let g:onedark_terminal_italics = 1
let g:airline_theme = 'onedark'
colorscheme onedark

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

"editorconfig-vim
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']


" CamelCaseMotion
"==============================================================================
nmap <silent> W <Plug>CamelCaseMotion_w
xmap <silent> W <Plug>CamelCaseMotion_w
omap <silent> W <Plug>CamelCaseMotion_w
nmap <silent> B <Plug>CamelCaseMotion_b
xmap <silent> B <Plug>CamelCaseMotion_b
omap <silent> B <Plug>CamelCaseMotion_b


" vim-javascript
"==============================================================================
let g:javascript_enable_domhtmlcss = 1
let g:javascript_conceal = 1


" tComment
"==============================================================================
map <Space>/ :TComment<CR>


" vim-niceblock
"==============================================================================
xmap I <Plug>(niceblock-I)
xmap A <Plug>(niceblock-A)


" tagbar
"==============================================================================
let g:tagbar_autoclose = 1
nmap <silent> <F9> :TagbarToggle<CR>


" ale
"==============================================================================
let g:ale_linters = {
            \   'javascript': ['eslint'],
            \   'python': ['flake8'],
            \   'scss': ['stylelint'],
            \   'typescript': ['eslint'],
            \}
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
let g:ale_fix_on_save = 1
let g:ale_floating_preview = 1
let g:ale_fixers = {
\   'javascript': ['eslint', 'prettier'],
\   'typescript': ['eslint', 'prettier'],
\   'typescriptreact': ['eslint', 'prettier'],
\   'vue': ['eslint'],
\   'css': ['prettier'],
\   'scss': ['prettier'],
\   'python': ['isort', 'black'],
\   'markdown': ['prettier'],
\   'nix': ['nixpkgs-fmt'],
\}


nmap <silent> <leader>pe <Plug>(ale_previous_wrap)
nmap <silent> <leader>ne <Plug>(ale_next_wrap)
" nnoremap <Leader>f <Plug>(ale_fix)
nnoremap <Leader>h :ALEDetail<CR>


" git and diff
"==============================================================================
autocmd MyAutoCmd BufReadPost fugitive://* set bufhidden=delete
command! -bang -nargs=+ Sgrep execute 'silent Ggrep<bang> <args>' | copen
map <Leader>1 :diffget LOCAL<CR>
map <Leader>2 :diffget BASE<CR>
map <Leader>3 :diffget REMOTE<CR>
set diffopt+=internal,algorithm:patience

" delimitMate
"==============================================================================
"<CR> remaped for neocomplete, don't forget add delimitMateCr
let g:delimitMate_expand_cr = 1
let g:delimitMate_expand_space = 1


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

" ionide-vim
let g:fsharp#lsp_auto_setup = 0

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

let g:racer_cmd = $HOME.'/.cargo/bin/racer'
let g:racer_experimental_completer = 1
autocmd MyAutoCmd FileType rust nmap gd <Plug>(rust-def)
autocmd MyAutoCmd FileType rust nmap gs <Plug>(rust-def-split)
autocmd MyAutoCmd FileType rust nmap gx <Plug>(rust-def-vertical)
autocmd MyAutoCmd FileType rust nmap K <Plug>(rust-doc)


" filetype specific settings
autocmd MyAutoCmd FileType html setlocal ts=2 sw=2 sta et sts=2 ai
autocmd MyAutoCmd FileType javascript setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType vue setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType json setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType typescript setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType typescript.tsx setlocal ts=2 sw=2 sta et sts=2 ai colorcolumn=110
autocmd MyAutoCmd FileType python let g:argwrap_tail_comma = 1

" save on focus lost
autocmd MyAutoCmd FocusLost * :silent! wall

" don't show trailing spaces in insert mode
autocmd MyAutoCmd InsertEnter * :set listchars-=trail:·
autocmd MyAutoCmd InsertLeave * :set listchars+=trail:·

" js, jsx
autocmd MyAutoCmd BufRead,BufNewFile *.js call s:FTjs()


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

" vue
autocmd FileType vue syntax sync fromstart
let g:vue_disable_pre_processors=1

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!
au FileType sql let &l:formatprg=g:nix_exes['pg_format'] . ' -'
