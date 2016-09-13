"hi Comment ctermfg=lightcyan
"hi Constant ctermfg=red
"hi LineNr ctermfg=grey
"hi Statement term=bold ctermfg=darkgreen
"hi Identifier term=italic ctermfg=yellow
"hi PreProc ctermfg=lightblue
setlocal autoindent sw=2 ts=2 expandtab

func! s:TryLinesBefore() abort
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
endfunc

func! s:GetAnsibleIncludeFile(fname) abort
  try
    let dir = s:TryLinesBefore()
  catch NoIncludeFileFoundError
    echoerr 'no include file found'
  endtry
  let fileName = substitute(a:fname, '^[a-z]*=', '', '')
  let rootPath = expand('%:p:h:h')
  return rootPath.'/'.dir.'/'.fileName
endfunc

redir => s:ansibleFunc
silent function /.*GetAnsibleIncludeFile.*
redir END

let s:funcWithArgs = matchstr(split(s:ansibleFunc), 'SNR.*GetAnsibleIncludeFile')
let s:funcName = substitute(s:funcWithArgs, '(.*$', '', '')
exe 'set includeexpr='.s:funcName.'(v:fname)'

" vim:set sw=2
