let s:mode = {
      \ 'edit': 'e',
      \ 'new': 'n',
      \ 'vnew': 'v' }

func! s:GoToFile(mode) abort "{{{
  let fileName = s:GetIniIncludeFile(expand('<cWORD>'))
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

func! s:GetVarFile(fname) abort "{{{
  let rootPath = expand('%:p:h')
  if match(a:fname, '^\[.*\]$') > -1
    let groupName = matchstr(a:fname, '^\[\zs[^:\]]\+')
    let fileName = '/group_vars/'.groupName
  elseif match(a:fname, '^\([#;]\+\)\?[a-zA-Z0-9_.][a-zA-Z0-9_.-]*$') > -1
    let fileName = '/host_vars/'.matchstr(a:fname,  '^\([#;]\+\)\?\zs[a-zA-Z0-9_.-]\+$')
  else
    throw 'InvalidSyntaxError: cannot match expression "'.a:fname.'"'
  endif
  return rootPath.fileName
endfunc "}}}

func! s:GetIniIncludeFile(fname) abort "{{{
  if expand('%:t') == 'hosts'
    let path =  s:GetVarFile(a:fname)
    return path
  endif
  return a:fname
endfunc "}}}

" includeexpr {{{
"redir => s:iniFunc
"silent function /.*GetIniIncludeFile.*
"redir END

"let s:funcWithArgs = matchstr(split(s:iniFunc), 'SNR.*GetIniIncludeFile')
"let s:funcName = substitute(s:funcWithArgs, '(.*$', '', '')
"exe 'set includeexpr='.s:funcName.'(v:fname)'
"}}}

" vim:set sw=2
