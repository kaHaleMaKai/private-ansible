set tabstop=2
set shiftwidth=2
set smarttab
set softtabstop=2
set tabstop=8
set autoindent
set expandtab

func! s:GetVimObjectForLookup()
  let word = expand('<cWORD>')
  let smallWord = expand('<cword>')
  let word = strpart(word, stridx(word, smallWord))
  let line = getline('.')
  let col = col('.')
  if Match(strpart(line, 0, col), '^\s*[a-zA-Z][a-zA-Z_0-9]*$')
    let token = ':' . word
  else
    let token = substitute(word, '[^a-zA-Z_0-9&:(].*', '', '')
    let token = substitute(token, '(.*', '()', '')
  endif
  return token
endfunc

func! s:GetHelp(expr)
  try
    exe 'h '.a:expr
  catch  /E149/
    exe 'h '.substitute(a:expr, '[^a-zA-Z0-9_]', '', 'g')
  endtry
endfunc

nnoremap <silent> <buffer> K :call <sid>GetHelp(<sid>GetVimObjectForLookup())<CR>
