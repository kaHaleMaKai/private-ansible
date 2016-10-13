setlocal autoindent sw=2 ts=2 expandtab

let s:mode = {
      \ 'edit': 'e',
      \ 'new': 'n',
      \ 'vnew': 'v' }

func! s:GoToFile(mode) abort "{{{
  let fileName = s:GetAnsibleIncludeFile(expand('<cWORD>'))
  if a:mode == s:mode.new
    wincmd n
  elseif a:mode == s:mode.vnew
    wincmd v
  endif
  exe 'e '.fileName
endfunc "}}}

" maps {{{
nnoremap <buffer> gf :call <SID>GoToFile('e')<CR>
nnoremap <buffer> <C-w>f :call <SID>GoToFile('n')<CR>
nnoremap <buffer> <C-w><C-f> :call <SID>GoToFile('n')<CR>
nnoremap <buffer> <C-w>e :call <SID>GoToFile('v')<CR>
nnoremap <buffer> <C-w><C-e> :call <SID>GoToFile('v')<CR>
" }}}

func! s:TryLinesBefore() abort "{{{
  for lineNr in reverse(range(1, line('.')))
    let line = getline(lineNr)
    if match(line, 'copy:') > -1
      return 'files'
    elseif match(line, 'template:') > -1
      return 'templates'
    elseif match(line, '^\s*[a-z_]*:') > -1
      throw 'NoIncludeFileFoundError'
    endif
  endfor
  throw 'NoIncludeFileFoundError'
endfunc "}}}"

func! s:GetAnsibleIncludeFile(fname) abort "{{{
  try
    let dir = s:TryLinesBefore()
  catch NoIncludeFileFoundError
    echoerr 'no include file found'
  endtry
  let fileName = substitute(a:fname, '^[a-z]*=', '', '')
  let rootPath = expand('%:p:h:h')
  return rootPath.'/'.dir.'/'.fileName
endfunc "}}}

" includeexplr {{{
"redir => s:ansibleFunc
"silent function /.*GetAnsibleIncludeFile.*
"redir END

"let s:funcWithArgs = matchstr(split(s:ansibleFunc), 'SNR.*GetAnsibleIncludeFile')
"let s:funcName = substitute(s:funcWithArgs, '(.*$', '', '')
"exe 'set includeexpr='.s:funcName.'(v:fname)'
" }}}


" vim:set sw=2

