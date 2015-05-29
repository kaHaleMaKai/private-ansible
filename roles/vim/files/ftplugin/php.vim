set tabstop=4
set shiftwidth=4
set smarttab
set softtabstop=4
set tabstop=8
set autoindent
set expandtab

let php_sql_query=1
" function! s:PhpVisualSelect(scope)
"   let s:scope = a:scope
"   if s:scope == 'innerkey' || s:scope == 'outerkey'
"     let s:kbuf = @k
"     normal "kvy
"     if @k == ':'
"       normal l
"     endif
"     let @k = s:kbuf
"   endif
"   if s:scope == 'innerword'
"     let s:special_leader = ':@<>_+$-'
"     let s:slash = ''
"   elseif  s:scope == 'outerword'
"     let s:special_leader = ':@<>_+$-'
"     let s:slash = '\/'
"   elseif  s:scope == 'innerkey'
"     let s:special_leader = '+$<>_-#'
"     let s:slash = ''
"   elseif  s:scope == 'outerkey'
"     let s:special_leader = '+$<>_-#'
"     let s:slash = '\/'
"   endif
"   let s:_register = @/
"   let s:search_string = '\<[$a-zA-Z' . s:special_leader . '][a-zA-Z0-9_><@+$\-' . s:slash . ']\+\>'
"   call search(s:search_string, 'ecW')
"   let s:lastCol = col('.')
"   call search(s:search_string, 'bcW')
"   exe 'normal v' . s:lastCol . '|'
"   let @/ = s:_register
" endfunction
"
" vnoremap <silent> ac <Esc>:call <SID>CljVisualSelect('outerword')<CR>
" onoremap <silent> ac :call <SID>CljVisualSelect('outerword')<CR>
" vnoremap <silent> ic <Esc>:call <SID>CljVisualSelect('innerword')<CR>
" onoremap <silent> ic :call <SID>CljVisualSelect('innerword')<CR>
" vnoremap <silent> ak <Esc>:call <SID>CljVisualSelect('outerkey')<CR>
" onoremap <silent> ak :call <SID>CljVisualSelect('outerkey')<CR>
" vnoremap <silent> ik <Esc>:call <SID>CljVisualSelect('innerkey')<CR>
" onoremap <silent> ik :call <SID>CljVisualSelect('innerkey')<CR>
