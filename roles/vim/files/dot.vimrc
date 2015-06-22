" vimrc from ansible
if !1 | finish | endif

if has('vim_starting')
  if &compatible
    set nocompatible
  endif

  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" general settings
set mouse=a
set ttyfast
set ttymouse=xterm2

if !exists("true")
  let true = 1
  lockvar true
endif
if !exists("false")
  let false = 0
  lockvar false
endif

set modeline
set hlsearch
hi Search cterm=reverse
set background=dark
set tags=tags;/
set t_Co=256
set number
set lazyredraw
set magic
set showmatch
set mat=2
set smartcase
set hlsearch
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
set encoding=utf8
set ffs=unix,dos,mac
set nobackup
set nowb
set noswapfile
set smarttab
set laststatus=2
set splitbelow
set splitright
set sw=2
set expandtab

call neobundle#begin(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'
NeoBundle 'tpope/vim-sensible'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-surround'
NeoBundle 'tpope/vim-repeat'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'bling/vim-airline'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'ervandew/supertab'
NeoBundle 'vim-scripts/TaskList.vim'
NeoBundle 'flazz/vim-colorschemes'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'https://gitlab.com/pycqa/flake8.git'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundleLazy 'ironcamel/vimchat'
NeoBundle 'rking/ag.vim'

" clojure specific
NeoBundleLazy 'vim-scripts/paredit.vim'
NeoBundleLazy 'tpope/vim-fireplace'
NeoBundleLazy 'guns/vim-clojure-static'
NeoBundleLazy 'tpope/vim-classpath'

"yaml
NeoBundleLazy 'stephpy/vim-yaml'

call neobundle#end()

filetype plugin indent on
NeoBundleCheck

syntax on
if !exists("g:colorscheme_sourced")
  let g:colorscheme_sourced = true
  colorscheme Monokai
  for opt in ["Normal", "NonText"]
    exe "hi " . opt . " ctermbg=none"
  endfor
  hi Normal ctermbg=none
  hi Normal ctermbg=none
endif

set nu
let mapleader = '-'

map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h
map <leader>td <Plug>TaskList
cmap w!! w !sudo tee > /dev/null %
nnoremap <silent> <leader>,<space> :let @/=''<CR>:<CR>

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:solarized_termcolors= 256
let g:solarized_termtrans = true
let g:solarized_bold = true
let g:solarized_underline = true
let g:solarized_italic = true

let g:syntastic_always_populate_loc_list = true
let g:syntastic_auto_loc_list = true
let g:syntastic_check_on_open = true
let g:syntastic_check_on_wq = false
let g:vim_path = substitute($MYVIMRC, 'rc', '', '')
let g:vimrc_res_path = g:vim_path . "/vimrc-res"
let g:SESSION_PATH = g:vimrc_res_path . '/sessions'
let g:NR_OF_SESSIONS = 10
let g:delete_trailing_ws = true

" autocommands
au BufWrite * :call DeleteTrailingWS()
au BufNewFile,BufRead *.ino set filetype=arduino
au BufNewFile,BufRead *.jsm set filetype=javascript

exe "so " . g:vimrc_res_path . "/" . "funcs.vim"
