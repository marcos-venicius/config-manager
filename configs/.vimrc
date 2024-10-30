let mapleader=' '
let maplocalleader=' '

set autoread
set fileformat=unix
set expandtab
set wildmenu
set hlsearch
set ruler
set nu
set rnu
set tabstop=2
set shiftwidth=2
set softtabstop=2
set smartindent
set autoindent
set path+=**
set nowrap
set smartcase
set ignorecase
set hidden
set splitbelow
set splitright
set nocursorline
set nobackup
set nowritebackup
set patchmode=off
set backupcopy=no
set backupskip=*
set backupdir=~/.vim/.backup/
set clipboard+=unnamedplus

colorscheme default

filetype plugin indent on
filetype plugin detect
syntax on

nnoremap <leader><space> :nohlsearch<cr>

autocmd FileType csharp set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType ruby set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType *.rb set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
au BufRead,BufNewFile *.rb set tabstop=2 shiftwidth=2 softtabstop=2 expandtab

autocmd FocusGained * checktime

let g:netrw_keepdir = 0
let g:netrw_winsize = 30
let g:netrw_banner = 0
hi! link netrwMarkFile Search

nnoremap - :Explore<CR>

highlight Comment ctermfg=green
highlight String ctermfg=green

let ghregex='\(^\|\s\s\)\zs\.\S\+'
let g:netrw_list_hide=ghregex
let g:netrw_liststyle = 3

function! Fmt()
  if &filetype == 'go'
    :!/usr/local/go/bin/go fmt .
  else
    echo "This is not a go file"
  endif
endfunction

command Fmt :call Fmt()
