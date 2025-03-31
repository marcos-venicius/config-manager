let mapleader=' '
let maplocalleader=' '

" remove GUI from GVim
set guioptions=
set autoread
set fileformat=unix
set expandtab
set wildmenu
set wildignore+=**/node_modules/**
set wildignore+=**/.git/**
set wildignore+=**/dist/**
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

filetype plugin indent on
filetype plugin detect
syntax on

autocmd FileType csharp set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.cs set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.c set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

autocmd FileType h set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType *.h set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au BufRead,BufNewFile *.h set tabstop=4 shiftwidth=4 softtabstop=4 expandtab

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

function! Conflicts()
  let l:conflicts = systemlist('for file in $(git diff --name-only --diff-filter=U --relative); do for line in $(grep --no-filename -n "<<<<<<< HEAD" $file | grep -oP --color=never "^\d+"); do echo $file:$line:1 git conflict; done; done')

  if empty(l:conflicts)
    echo "No conflicts found"
    return
  endif

  call setqflist([], 'r', {'title': 'Merge Conflicts', 'lines': l:conflicts})

  copen
  cc
endfunction

command! Conflicts call Conflicts()

function! GetSelectedText()
  let l:old_reg = getreg('"')
  let l:old_regtype = getregtype('"')
  normal! gvy
  let l:selected_text = getreg('"')
  call setreg('"', l:old_reg, l:old_regtype)
  return l:selected_text
endfunction

function! SearchSelection()
  let l:selection = GetSelectedText()
  let l:escaped_selection = escape(l:selection, ' .*~^$[]\') " Escape special characters
  echo "Grepping \"" . l:escaped_selection . "\"..."
  execute "vimgrep /" . l:escaped_selection . "/gj **/*"
  copen
endfunction

vnoremap F :call SearchSelection()<cr>

nnoremap - :Explore<CR>
nnoremap <leader>r :source ~/.vimrc<CR>
nnoremap <leader><space> :nohlsearch<cr>
nnoremap <leader>s :copen<cr>
nnoremap <leader>c :cclose<cr>
nnoremap <leader>n :cnext<cr>zz
nnoremap <leader>p :cprev<cr>zz

function! AddTodoBoilerplate()
    let l:date = strftime("%A %d-%m-%y %H:%M - %H:%M")

    if getline('.') ==# ''
        execute "normal! 0i\"\" " . l:date . " Todo\<Esc>0l"
    else
        execute "normal! o\"\" " . l:date . " Todo\<Esc>0l"
    endif
endfunction

augroup TodoListFile
  autocmd!
  autocmd BufRead,BufNewFile *.todo* nnoremap <leader>t <esc>$BDaTodo<esc>0l
  autocmd BufRead,BufNewFile *.todo* nnoremap <leader>i <esc>$BDaDoing<esc>0l
  autocmd BufRead,BufNewFile *.todo* nnoremap <leader>c <esc>$BDaDone<esc>0l
  autocmd BufRead,BufNewFile *.todo* nnoremap <leader>a :call AddTodoBoilerplate()<cr>
augroup END
