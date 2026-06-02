let g:mapleader=" "
let g:maplocalleader=" "

set nocompatible " disable vi compatibility to avoid unexpected issues

set encoding=UTF-8
filetype on
syntax on
filetype plugin on
filetype indent on

set spell " ]s to next spelling, [s to prev spelling, 'zg' to add to dictionary

set showcmd
set showmode
set showmatch
set history=1000 " default is 20

set omnifunc=syntaxcomplete#Complete

" enable spelling suggestions for auto-completion
set complete+=k
set completeopt=menu,menuone,noinsert

set path+=**
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx,node_modules/,.git/
set signcolumn=no
set expandtab
set wildmenu
set hlsearch
set ruler
set number
set relativenumber
set tabstop=2
set shiftwidth=2
set softtabstop=2
set smartindent
set autoindent
set nowrap
set smartcase
set ignorecase
set hidden
set splitbelow
set splitright
set nocursorline
set smarttab
set incsearch
set nolazyredraw
set magic
set showmatch
set noswapfile

" GVIM options
set guioptions-=m " remove menu bar
set guioptions-=T " remove toolbar
set guioptions-=r " remove right-hand scroll bar
set guioptions-=L " remove left-hand scrollbar

set fileformat=unix
set fileformats=unix,dos

nnoremap <leader><leader> :nohlsearch<cr>
noremap <a-up> <c-w>+
noremap <a-down> <c-w>-
noremap <a-left> <c-w>>
noremap <a-right> <c-w><
map <leader>e :Lex<CR>
vnoremap <a-j> :m '>+1<CR>gv=gv
vnoremap <a-k> :m '>-2<CR>gv=gv

" Disable auto commenting in a new line
autocmd Filetype * setlocal formatoptions-=c formatoptions-=r  formatoptions-=o
autocmd Filetype c setlocal tabstop=4 shiftwidth=4 expandtab
autocmd Filetype python setlocal tabstop=4 shiftwidth=4 expandtab

let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_showhide=1
let g:netrw_winsize=20

if has('gui_running')
  " Start Lex Tree and put the cursor back in the other window.
  autocmd VimEnter * :Lexplore | wincmd p
endif

set laststatus=2
set statusline=
set statusline+=%2*
set statusline+=%{StatuslineMode()}
set statusline+=\ 
set statusline+=%1*
set statusline+=\ 
set statusline+=%3*
set statusline+=%f
set statusline+=%4*
set statusline+=%m
set statusline+=%=
set statusline+=%h
set statusline+=%r
set statusline+=%4*
set statusline+=%c
set statusline+=/
set statusline+=%l
set statusline+=/
set statusline+=%L
set statusline+=\ 
set statusline+=%1*
set statusline+=|
set statusline+=%y
set statusline+=\ 
set statusline+=%4*
set statusline+=%P
set statusline+=\ 
set statusline+=%3*
set statusline+=t:
set statusline+=%n
set statusline+=\ 


" Colors
hi User2 ctermbg=white ctermfg=black guibg=white guifg=black
hi User1 ctermbg=white ctermfg=black guibg=white guifg=black
hi User3 ctermbg=white  ctermfg=black guibg=white guifg=black
hi User4 ctermbg=white ctermfg=black guibg=white guifg=black


" Mode
function! StatuslineMode()
  let l:mode=mode()
  if l:mode==#"n"
    return "NORMAL"
  elseif l:mode==#"V"
    return "VISUAL LINE"
  elseif l:mode==?"v"
    return "VISUAL"
  elseif l:mode==#"i"
    return "INSERT"
  elseif l:mode ==# "\<C-V>"
    return "V-BLOCK"
  elseif l:mode==#"R"
    return "REPLACE"
  elseif l:mode==?"s"
    return "SELECT"
  elseif l:mode==#"t"
    return "TERMINAL"
  elseif l:mode==#"c"
    return "COMMAND"
  elseif l:mode==#"!"
    return "SHELL"
  else
    return "VIM"
  endif
endfunction
