if !exists("user_funcs_imported")
  let user_funcs_imported = true

  func! DeleteTrailingWS()
    if g:delete_trailing_ws == 1
      exe "normal mz"
      %s/\s\+$//ge
      exe "normal `z"
    endif
  endfunc

  func! s:ToggleTrailingWSDeletionFn()
    let g:delete_trailing_ws = !g:delete_trailing_ws
  endfunc
  command! -nargs=0 ToggleTrailingWSDeletion call s:ToggleTrailingWSDeletionFn()

  func! s:UnsetTrailingWSDeletionFn()
    let g:delete_trailing_ws = 0
  endfunc
  command! -nargs=0 UnsetTrailingWSDeletion call s:UnsetTrailingWSDeletionFn()

  func! s:SetTrailingWSDeletionFn()
    let g:delete_trailing_ws = 1
  endfunc
  command! -nargs=0 SetTrailingWSDeletion call s:SetTrailingWSDeletionFn()

  func! s:WSFn(override, force)
    let current_ws_state = g:delete_trailing_ws
    let g:delete_trailing_ws = 0
    if a:override
      if a:force
        x!
      else
        x
      endif
    else
      if a:force
        w!
      else
        w
      endif
    endif
    let g:delete_trailing_ws = current_ws_state
  endfunc

  command! -nargs=0 WS call s:WSFn(0, 0)
  command! -nargs=0 WWS call s:WSFn(0, 1)
  command! -nargs=0 XS call s:WSFn(0, 0)
  command! -nargs=0 XXS call s:WSFn(0, 1)

  function! s:ShowVimColors()
    exe '! feh ' . g:VIMRC_PATH . '/' . 'vimrc-res/vimcolors.png &'
  endfunction
  command! ShowVimColors call s:ShowVimColors()

  function! s:EditColorScheme(scheme)
    let scheme = g:VIMRC_PATH . '/bundle/vim-colorschemes/colors/' . a:scheme . '.vim'
    let winnr = bufwinnr(bufname('vim-colorschemes'))
    echo scheme
    echo winnr
    silent! execute  winnr < 0 ? 'botright new ' . fnameescape('editColorScheme') : winnr . 'wincmd w'
    setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
    silent! execute 'edit ' . scheme
  "   silent! execute 'resize ' . line('$')
    silent! redraw
    silent! execute 'au! BufUnload <buffer> execute bufwinnr(' . bufnr('#') . ') . ''wincmd w'''
  "   silent! execute 'wincmd p'
  endfunction
  command! -nargs=1 EditColorScheme call s:EditColorScheme(<q-args>)

  function! Reduce(ffn, list) "{{{3
    if empty(a:list)
      return ''
    else
      let list = copy(a:list)
      let s:acc = remove(list, 0)
      let ffn = substitute(a:ffn, '\<v:acc\>', "s:acc", 'g')
      for val in list
        let s:acc = eval(substitute(ffn, '\<v:val\>', val, 'g'))
      endfor
      return s:acc
    endif
  endfunction

  function! s:PrintLine()
    exe 'echo ''' . substitute(getline('.'), '^\s\+\|\s\+$', '', '') . ''''
  endfunction
  command! -nargs=0 PrintLine call s:PrintLine()

  function! s:ToDoBack()
      silent exe '.-1r ! tail -n 1 is.done' | silent exe 'silent :! sed -i "\$ d" is.done'
  endfunction

  function! g:SetSpecificMaps()
    if (expand('%:t')) == 'to.do'
      nnoremap <silent> <F5> :exe ':! echo "' . getline('.') . '" >> is.done'<CR>"_dd
      nnoremap <silent> <F6> :call <sid>ToDoBack()<CR>
    endif
  endfunction

  function! g:Tabularize(range, ...)
    let range = a:range
    let args = copy(a:000)
    let formatters = map(copy(args), 'shellescape(''%s'', 1) . v:val')
    let cols = map(range(len(copy(args))), '''$'' . string(v:val+1)')
    exec(range . '!awk ''{printf "' . join(formatters, ', ') . '\n", ' . join(cols, ', ') . '}''')
  endfunction

  function! s:AddToDo(todo)
    let filename = expand('%')
    exec '! echo ' . filename . ': ' . shellescape(a:todo, 1) . ' >> ~/to.do'
  endfunction

  command! -nargs=1 TODO call s:AddToDo(<q-args>)

  function! s:LoadSession(session)
    let session = substitute(a:session, '\(\.vim$\|^[^/]*/\)', '', 'g') . '.vim'
    silent exe 'so ' . g:SESSION_PATH . '/' . session
    echo 'loading session ' . session
    let s:current_session = session
    wincmd t
    wincmd q
    NERDTree
    wincmd =
  endfunc
  command! -nargs=1 LoadS call s:LoadSession(<q-args>)

  function! s:GetSessionName()
    return s:current_session
  endfunc
  command! -nargs=0 GetS echo s:GetSessionName()

  function! s:SaveSession(bang, ...)
    let bang = a:bang ? '!' : ''
    if a:0 < 1 || a:1 == ''
      let session = s:current_session
    else
      let session = substitute(a:1, '\(\.vim$\|^[^/]*/\)', '', 'g') . '.vim'
    endif
    if session == ''
      echo "Error: no session give"
    else
      silent exe 'mksession' . bang . ' ' . g:SESSION_PATH . '/' . session
      echo 'saving session ''' . session . ''''
    endif
    let s:current_session = session
    return session
  endfunc
  command! -nargs=? -bang SaveS call s:SaveSession(<bang>0, <q-args>)

  " function! s:EnqueueSessions()
  "   let path = g:SESSION_PATH
  "   for i in

  function! s:ListSessionsInShell()
    let path = g:SESSION_PATH
    let delim = ''
    for i in range(1, 20)
      let delim = delim . '+'
    endfor
    let emptyline = 'echo ""'
    let line = 'echo ''' . delim . ''''
    exe '!' . emptyline
          \ . ' && ' . line
          \ . ' && ' . emptyline
          \ . ' && ls -t1 ' . path . '/*.vim'
          \ . ' && ' . emptyline
          \ . ' && ' . line
          \ . ' && ' . emptyline
  endfunc
  command! -nargs=0 ListS call s:ListSessionsInShell()

  function! s:RemoveSession(session)
    let path = g:SESSION_PATH
    let session = substitute(a:session, '\(\.vim$\|^[^/]*/\)', '', 'g') . '.vim'
    let file = shellescape(path . '/' . session)
    let error = system('rm ' . file . ' 2> /dev/null; echo $?')
    if !error
      echo "removed session '" . a:session . "'"
    else
      echo "no file found for session '" . a:session . "'"
    endif
  endfunc

  command! -nargs=1 RemoveS call s:RemoveSession(<f-args>)

  command! -nargs=0 AC call system("ACPI")

  function! FindProjectVim(cur_dir)
    let cur_dir = a:cur_dir
    let project_file = '.project.vim'
    let found_config = system('ls ' . cur_dir . '/' . project_file . ' >/dev/null 2>&1; echo $?') == 0
    if (found_config)
      return cur_dir . '/' . project_file
    else
      if cur_dir != '/'
        return FindProjectVim(fnamemodify(cur_dir, ':h'))
      else
        return 0
    endif
  endfunction

  function! MatchesRegEx(str, pattern)
    return matchstr(a:str, a:pattern) != ''
  endfunc

  function! IsInt(val)
    return MatchesRegEx(a:val, '^-\?[0-9]\+$')
  endfunc

  function! IsFloat(val)
    return MatchesRegEx(a:val, '^-\?[0-9]\+\.[0-9]*')
  endfunc

  function! IsHash(val)
    return MatchesRegEx(a:val, '^{.*}$')
  endfunc

  function! IsList(val)
    return MatchesRegEx(a:val, '^\[.*\]$')
  endfunc

  function! IsBool(val)
    return MatchesRegEx(a:val, '^\(true\|false\)$')
  endfunc

  function! JSHintParseVal(val)
    let val = a:val
    if IsInt(val) || IsFloat(val)
      return eval(val)
    elseif IsHash(val)
      return 'hash'
    elseif IsBool(val)
      return 'bool'
    else
      return 'string'
    endif
  endfunc

  function! IsKVPair(str)
    return MatchesRegEx(a:str, '^[a-z][a-zA-Z]* *: *[a-z0-9]\+')
  endfunc

  function! JSHintLineToHash(line)
    let line = substitute(a:line, ' *#.*$\|^ *\| *$', '', 'g')
    if len(line) == 0
      return {}
    elseif IsKVPair(line)
      let [k, v] = split(line, ' *: *')
      let m = {}
      let m[k] = v
      return m
    else
      echo 'error: line is badly formatted'
      echo line
      return {}
    endif
  endfunc

  function! ParseJSHintConfig(file)
    let m = {}
    let file = readfile(a:file)
    for line in file
      call extend(m, JSHintLineToHash(line))
    endfor
    return m
  endfunc!

  function! s:FnStartVimChat()
    NeoBundleSource vimchat
    VimChat
  endfunc

  command! -nargs=0 StartVimChat call s:FnStartVimChat()
endif
