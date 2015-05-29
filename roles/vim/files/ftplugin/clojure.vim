" nnoremap <silent> <leader>;; :call PareditSmartJumpOpening(0)<CR>:call PareditWrap("(",")")<CR>acomment<C-R>=PareditEnter()<C-M><ESC>:call PareditSmartJumpOpening(0)<CR>
" inoremap <leader>. `
" onoremap <leader>. `
" nnoremap <silent> <leader>b h/\S<CR>:call PareditSmartJumpClosing(0)<CR>a<C-R>=PareditEnter()<C-M><C-R>=PareditInsertOpening('(',')')<C-M><C-o>h<C-o>:noh<CR>

" non-leader maps
" nnoremap <CR> i<C-R>=PareditEnter()<C-M><ESC>l
" nnoremap <silent> <leader><CR> /\(\s\\|\n\)<CR>xi<C-R>=PareditEnter()<C-M><ESC>l:noh<CR>
" TODO: line above: replacement of white space or new line doesn't work yet
" inoremap <silent> <leader><CR> <C-o>/\s<CR><C-o>x<C-R>=PareditEnter()<C-M><C-o>l<C-o>:noh<CR>
nnoremap <BS> X
nnoremap <DEL> x
" nnoremap <silent> <C-k> :call PareditFindDefunBck()<CR>
" nnoremap <silent> <C-j> :call PareditFindDefunFwd()<CR>
" nnoremap <silent> <leader>m :call search('[(\[\{]', 'W')<CR>
" nnoremap <silent> <leader>n :call search('[)\]\}]', 'bW')<CR>
" nnoremap <silent> <leader>ic :call search('\[', 'Wc')<CR>Xi<C-r>=PareditEnter()<C-m><C-r>=PareditEnter()<C-m><C-o>k<C-r>=PareditInsertOpening('"', '"')<C-m>

func! s:ConnectToNRepl(port)
  exe "Connect nrepl://localhost:" . a:port
endfunc

command! -nargs=1 NREPL call s:ConnectToNRepl(<q-args>)

function! s:EvalVisualRange()
  let s:_register = @"
  silent normal y
  exe 'Eval ' . @"
  let @" = s:_register
endfunction
vnoremap <silent> cpp :call <SID>EvalVisualRange()<CR>

function! s:CljVisualSelect(scope)
  let s:scope = a:scope
  if s:scope == 'innerkey' || s:scope == 'outerkey'
    let s:kbuf = @k
    normal "kvy
    if @k == ':'
      normal l
    endif
    let @k = s:kbuf
  endif
  if s:scope == 'innerword'
    let s:special_leader = ':@<>_+$-'
    let s:slash = ''
  elseif  s:scope == 'outerword'
    let s:special_leader = ':@<>_+$-'
    let s:slash = '\/'
  elseif  s:scope == 'innerkey'
    let s:special_leader = '+$<>_-#'
    let s:slash = ''
  elseif  s:scope == 'outerkey'
    let s:special_leader = '+$<>_-#'
    let s:slash = '\/'
  endif
  let s:_register = @/
  let s:search_string = '[a-zA-Z' . s:special_leader . '][a-zA-Z0-9_><@+$\-' . s:slash . ']\+'
  call search(s:search_string, 'ecW')
  let s:lastCol = col('.')
  call search(s:search_string, 'bcW')
  exe 'normal v' . s:lastCol . '|'
  let @/ = s:_register
endfunction

vnoremap <silent> ac <Esc>:call <SID>CljVisualSelect('outerword')<CR>
onoremap <silent> ac :call <SID>CljVisualSelect('outerword')<CR>
vnoremap <silent> ic <Esc>:call <SID>CljVisualSelect('innerword')<CR>
onoremap <silent> ic :call <SID>CljVisualSelect('innerword')<CR>
vnoremap <silent> ak <Esc>:call <SID>CljVisualSelect('outerkey')<CR>
onoremap <silent> ak :call <SID>CljVisualSelect('outerkey')<CR>
vnoremap <silent> ik <Esc>:call <SID>CljVisualSelect('innerkey')<CR>
onoremap <silent> ik :call <SID>CljVisualSelect('innerkey')<CR>

" vim: ft=vim
