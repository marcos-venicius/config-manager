let mapleader=' '
let maplocalleader=' '

" remove GUI from GVim
set guioptions=
set autoread
set fileformat=unix
set expandtab
set wildmenu
set wildignore+=*node_modules*"
set hlsearch
set foldenable
set foldmethod=manual
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
set incsearch
set splitright
set cursorline
set noautochdir

set backup
set swapfile
set directory=/tmp
set dir=/tmp
set backupdir=/tmp
set backupdir=/tmp
set clipboard+=unnamedplus

colorscheme xcode

filetype plugin indent on
filetype plugin detect
syntax on

autocmd FileType csharp set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType make set tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab

autocmd FileType ruby set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType *.rb set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
au BufRead,BufNewFile *.rb set tabstop=2 shiftwidth=2 softtabstop=2 expandtab

autocmd FileType go set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.go set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.go set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType python set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.py set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.py set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FocusGained * checktime

let g:netrw_keepdir = 0
let g:netrw_winsize = 30
let g:netrw_banner = 0
hi! link netrwMarkFile Search


highlight Comment ctermfg=green
highlight String ctermfg=green

let ghregex='.*\.swp$,\~$,\.orig$'
let g:netrw_list_hide=ghregex
"let g:netrw_liststyle = 3

function! FmtGo()
  :!/usr/local/go/bin/go fmt .
endfunction

function! FmtAoc()
  let l:path=expand('%:p')
  silent execute '%!python3 /home/dev/projects/python/aoc/fmt.py ' . l:path
endfunction


au BufRead,BufNewFile *.go command Fmt :call FmtGo()
au BufRead,BufNewFile *.coa nnoremap <leader>f :call FmtAoc()<CR>

nnoremap - :Explore<CR>
nnoremap <leader>r :source ~/.vimrc<CR>
nnoremap <leader><space> :nohlsearch<cr>
nnoremap <leader>s :copen<cr>
nnoremap <leader>c :cclose<cr>
nnoremap <leader>n :cnext<cr>
nnoremap <leader>p :cprev<cr>
