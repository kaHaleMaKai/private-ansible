setlocal autoindent sw=2 ts=2 expandtab

" maps {{{
nnoremap <buffer> gf :call <SID>GoToFile('e')<CR>
nnoremap <buffer> <C-w>f :call <SID>GoToFile('n')<CR>
nnoremap <buffer> <C-w><C-f> :call <SID>GoToFile('n')<CR>
nnoremap <buffer> <C-w>e :call <SID>GoToFile('v')<CR>
nnoremap <buffer> <C-w><C-e> :call <SID>GoToFile('v')<CR>
" }}}

if exists("g:loaded_yaml_vim") || &cp || v:version < 700
  finish
endif
let g:loaded_yaml_vim = 1
let s:DIR_TYPE = 0
let s:FILE_TYPE = 1
let s:LEVEL_TYPE = 2

func! s:NewLocation(dir, ...)  abort "{{{
  let location = {'dir': type(a:dir) == v:t_list ? a:dir : [a:dir]}
  let location.type = s:LEVEL_TYPE
  if !a:0
    let location.level = 0
  else
    if type(a:1) == v:t_number
      let location.level = a:1
    elseif type(a:1) == v:t_string
      let location.file = a:1
      let location.type = a:0 > 1 ? a:2 : s:FILE_TYPE
    endif
  endif
  func! location.until() abort "{{{
    if has_key(self, 'level')
      return self['level']
    elseif has_key(self, 'file')
      return self['file']
    endif
  endfunc "}}}

  return location
endfunc "}}}

let s:mode = {
      \ 'edit': 'e',
      \ 'new': 'n',
      \ 'vnew': 'v' }
let s:includeStmts = {
      \ 'copy:': s:NewLocation('files', 1),
      \ 'template:': s:NewLocation('templates', 1),
      \ 'include:': s:NewLocation(''),
      \ 'hosts:': s:NewLocation(['host_vars', 'group_vars'], 'site.yml'),
      \ 'role:': s:NewLocation('roles'),
      \ 'roles:': s:NewLocation('roles') }

func! s:GoToFile(mode) abort "{{{
  let fileName = s:GetAnsibleIncludeFile(expand('<cWORD>'))
  if a:mode == s:mode.new
    wincmd n
  elseif a:mode == s:mode.vnew
    wincmd v
  endif
  exe 'e '.fileName
endfunc "}}}

func! s:GoUp(location) abort "{{{
  let dir = a:location.dir[0]
  let until = a:location.until()
  let type = a:location.type
  if type(until) == v:t_string
    if type == s:FILE_TYPE
      let result = findfile(until, dir.';')
    elseif type == s:DIR_TYPE
      let result = finddir(until, dir.';')
    else
      throw 'IllegalArgumentError'
    endif
  endif
  let nextDir = fnamemodify(dir, ":p:h")
  if until > 0
    return s:GoUp(s:NewLocation(nextDir, until - 1))
  else
    return s:NewLocation(nextDir)
  endif
endfunc "}}}

func! s:GetFirstPath(baseDir, dirs, fileName) abort "{{{
  for dir in a:dirs
    let path = a:baseDir .'/'.dir.'/'.a:fileName
    if filereadable(path) || isdirectory(path)
      return path
    endif
  endfor
  throw new FileNotFoundError
endfunc "}}}


func! s:TryLinesBefore(data) abort "{{{
  for lineNr in reverse(range(1, line('.')))
    let line = getline(lineNr)
    for [k, v] in items(a:data)
      if match(line, k) > -1
        return v
      endif
    endfor
    if match(line, '^\s*[a-z_]*:') > -1
      throw 'NoIncludeFileFoundError'
    endif
  endfor
  throw 'NoIncludeFileFoundError'
endfunc "}}}"

func! s:GetAnsibleIncludeFile(fname) abort "{{{
  try
    let location = s:TryLinesBefore(s:includeStmts)
  catch NoIncludeFileFoundError
    echoerr 'no include file found'
  endtry
  let fileName = substitute(a:fname, '^[a-z]*=', '', '')
  if fileName[0] == '/'
    return fileName
  endif
  let rootPath = s:GoUp(s:NewLocation(expand('%:p'), location.until, location.type))
  let filePath = s:GetFirstPath(rootPath.dir[0], location.dir, fileName)
  return substitute(filePath, '/\+', '/', 'g')
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
