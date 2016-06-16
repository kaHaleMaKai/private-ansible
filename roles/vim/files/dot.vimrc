" vimrc from ansible
if !1 | finish | endif

set foldmethod=marker
let mapleader = '-'

if has('vim_starting') "{{{1
  if &compatible
    set nocompatible
  endif
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif " 1}}}"

" global variables {{{1
if !exists("true")
  let true = 1
  lockvar true
endif
if !exists("false")
  let false = 0
  lockvar false
endif
if !exists("arg_err")
  let arg_err = "arg_err"
  lockvar arg_err
endif
" }}}
" vim related paths {{{1
let g:vim_path = substitute($MYVIMRC, 'rc', '', '')
let g:vimrc_res_path = g:vim_path . '/vimrc-res'
let g:SESSION_PATH = g:vimrc_res_path . '/sessions'
let g:NR_OF_SESSIONS = 10
let g:delete_trailing_ws = true
" 1}}}

" neobundles {{{
call neobundle#begin(expand('~/.vim/bundle/'))
exe "so " . g:vimrc_res_path . "/" . "bundles.vim"
call neobundle#end()

filetype plugin indent on
NeoBundleCheck

syntax on
" }}}

" global options {{{1
set mouse=a
set ttyfast
set ttymouse=xterm2
set completeopt=menu,longest
set modeline
set hlsearch
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
set wildmenu
set expandtab
set nu
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
" }}}

" global variables {{{1
" syntastic {{{2
let g:syntastic_always_populate_loc_list = true
let g:syntastic_auto_loc_list = true
let g:syntastic_check_on_open = true
let g:syntastic_check_on_wq = false
let g:syntastic_mode_map = { 'passive_filetypes': ['java'] }
" 2}}}
" CtrlP {{{
let g:ctrlp_extensions = ['funky']
let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden --ignore-case --ignore ".git" --ignore ".hg" --ignore ".svn" -g ""'
" 2}}}
" ultisnippets {{{2
let g:UltiSnipsJumpBackwardTrigger = '<c-j>'
let g:UltiSnipsJumpForwardTrigger = '<c-k>'
let g:UltiSnipsExpandTrigger = '<c-l>'
" 2}}}
" taglist {{{2
let g:Tlist_Use_Right_Window = 1
" 2}}}
" vim-mark-down {{{2
let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'sql', 'mysql', 'php', 'java']"
" 2}}}
" vim-reveal {{{2
let g:reveal_config = {
    \ 'path': '$HOME/Documents/presentations/reveal.js/',
    \ 'theme' : 'my-solarized',
    \ 'transition': 'fade',
    \ 'author': 'Lars Winderling'
    \ }
" other options go into g:reveal_default_config as key: val
" 2}}}
" vimchat {{{2
let g:vimchat_browser_cmd = 'chromium-browser'
let g:vimchat_extendedHighlighting = 1
" 2}}}
" vdebug {{{2
let g:vdebug_keymap = {
\    "run" : "r",
\    "run_to_cursor" : "<CR>",
\    "step_over" : "o",
\    "step_into" : "i",
\    "step_out" : "p",
\    "close" : "c",
\    "detach" : "d",
\    "set_breakpoint" : "n",
\    "get_context" : "g",
\    "eval_under_cursor" : "e",
\    "eval_visual" : "<Leader>e"
\}
" 2}}}
" local vimrc settings {{{2
let g:localvimrc_event = ["BufEnter"]
let g:localvimrc_ask = 0
let g:localvimrc_whitelist = ["/usr/local/repos/pacs/"]
"2}}}

" 1}}}
" source vim resources {{{1
exe "so " . g:vimrc_res_path . "/" . "funcs.vim"
exe "so " . g:vimrc_res_path . "/" . "commands.vim"
exe "so " . g:vimrc_res_path . "/" . "maps.vim"
" color scheme {{{2
let g:current_colorscheme = ''
let g:default_colorscheme = "synic"
call SetColorscheme()
" 2}}}
" 1}}}

" autocommands {{{1
au BufWrite * :call DeleteTrailingWS()
au BufNewFile,BufRead *.md  set filetype=markdown
au BufNewFile,BufRead *.ino set filetype=arduino
au BufNewFile,BufRead *.jsm set filetype=javascript
au BufNewFile,BufRead *.j2 set filetype=j2
au BufNewFile,BufRead *.gradle set filetype=groovy
" 1}}}

" Add the virtualenv's site-packages to vim path {{{1
py << EOF
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  sys.path.insert(0, project_base_dir)
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF
" 1}}}
