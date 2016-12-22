if !exists("g:user_funcs_imported")
  let g:user_funcs_imported = true

  " ++++++++++++++++++++ script local variables ++++++++++++++++++++
  lockvar s:user_funcs_imported
  let s:default_project_files = ['.git', 'site.yml', 'pom.xml']
  lockvar s:default_project_files

  if !exists("s:type_dict")
    let s:type_dict = { type(0): "int",
      \                 type(""): "str",
      \                 type(function("tr")): "funcref",
      \                 type([]): "list",
      \                 type({}): "dict",
      \                 type(0.0): "float",
      \                 255: "object"}
    lockvar s:type_dict
  endif

  func! DefineTypes(...) abort "{{{
    let scope = strpart(a:0 ? a:1 : 'g', 0, 1) . ':'
    if !exists(scope."types_defined")
      for [k, v] in items(s:type_dict)
        if !exists(scope .v)
          exe "let ".scope.v "=" k
          exe "lockvar ".scope.v
        endif
      endfor
      exe 'let '.scope.'types_defined = g:true'
    endif
  endfunc "}}}
  call DefineTypes()

  " types to be interpreted as iterable
  let s:iterableTypes = [g:str, g:list, g:dict]
  lockvar s:iterableTypes

  let s:valueTypes = [g:int, g:str, g:float]
  lockvar s:valueTypes

  " types to be interpreted as indexable
  let s:indexableTypes = [g:list, g:dict]
  lockvar s:indexableTypes

  if !exists("s:empty_singletons")
    let s:empty_singletons = {type(0): 0,
      \                       type(""): "",
      \                       type([]): [],
      \                       type({}): {},
      \                       type(0.0): 0.0}
    lockvar s:empty_singletons
  endif


  let Time = {}
  func! Time.GetHours() dict abort "{{{
    return str2nr(strftime("%H"))
  endfunc "}}}
  func! Time.GetMinutes() dict abort "{{{
    return str2nr(strftime("%M"))
  endfunc "}}}
  lockvar Time

  " ++++++++++++++++++++ functions ++++++++++++++++++++
  "
  " Check if variable is iterable.
  "
  " types string, list and dict are defined as iterable
  func! IsIterable(var) abort "{{{
    return index(s:iterableTypes, type(a:var)) > -1
  endfunc "}}}

  " Check if variable is indexable
  "
  " type list and dict are defined as indexable
  func! IsIndexable(Obj) abort "{{{
    return index(s:indexableTypes, type(a:Obj)) > -1
  endfunc "}}}

  func! IsValueType(Obj) abort "{{{
    return index(s:valueTypes, type(a:Obj)) > -1
  endfunc "}}}

  " Check if el is in iterable
  "
  " @throws TypeError
  func! Contains(iterable, el) abort "{{{
    let type = type(a:iterable)
    let res = g:false
    if type == g:str
      let res = stridx(a:iterable, a:el) > -1
    elseif type == g:list
      let res = index(a:iterable, a:el) > -1
    elseif type == g:dict
      let res = has_key(a:iterable, a:el)
    else
      throw 'TypeError: Contains() expects first argument to be iterable'
    endif
    return res
  endfunc "}}}


  func! Max(...) abort "{{{
    return max(a:000)
  endfunc "}}}

  func! GetArg(idx, ...) abort "{{{
    if type(a:idx) != g:int
      throw 'TypeError: GetArg expects first argument to be int'
    else
      return a:000[a:idx]
    endif
  endfunc "}}}

  " Get key from container, optionally safely.
  "
  " @args:
  " container -- indexable
  " key -- key to lookup
  " ...a:1 -- default in case lookup fails
  "
  " @throws TypeError, KeyNotFoundError
  func! Get(container, key, ...) abort "{{{
    if !IsIndexable(a:container)
      throw 'TypeError: ' . string(a:container) . ' is not indexable'
    endif
    try
      let val = a:container[a:key]
    catch /E684\|E716/
      if a:0
        let val = a:1
      else
        throw "KeyNotFoundError: " . string(a:key) . " not present in " . string(a:container)
      endif
    endtry
    return val
  endfunc "}}}

  func! AsDict(arg, ...) abort "{{{
    if !a:0
      if !IsList(a:arg)
        throw 'TypeError: AsDict() expects list as argument'
      endif
      let li = a:arg
      let length = len(li)
      if length % 2 != 0
        throw 'TypeError: AsDict() needs even number of keys and values'
      else
        let tmp = {}
        let idx = 0
        while idx < length
          let [key, val] = li[idx : idx+1]
          let tmp[key] = val
          let idx += 2
        endwhile
      endif
    elseif a:0
      let li = [a:arg]
      call extend(li, a:000)
      let tmp = AsDict(li)
    endif
    return tmp
  endfunc "}}}

  func! Min(...) abort "{{{
    return min(a:000)
  endfunc "}}}

  func! Order(x, y) abort "{{{
    return a:x > a:y ? [a:y, a:x] : [a:x, a:y]
  endfunc "}}}

  func! Bool(arg) abort "{{{
    let _type = type(a:arg)
    if _type == g:int
      return a:arg != s:empty_singletons[g:int]
    elseif _type == g:str
      return a:arg != s:empty_singletons[g:str]
    elseif _type == g:funcref
      return g:true
    elseif _type == g:list
      return a:arg != s:empty_singletons[g:list]
    elseif _type == g:dict
      return a:arg != s:empty_singletons[g:dict]
    elseif _type == g:float
      return a:arg != s:empty_singletons[g:float]
    endif
  endfunc "}}}

  let g:Truthy = function('Bool')

  func! Match(expr, pattern, ...) abort "{{{
    let m = 0
    if a:0 == 0
      let m = match(a:expr, a:pattern)
    elseif a:0 == 1
      let m = match(a:expr, a:pattern, a:1)
    else
      let m = match(a:expr, a:pattern, a:1, a:2)
    endif
    return m > -1
  endfunc "}}}

  func! DeleteTrailingWS() abort "{{{
    if g:delete_trailing_ws == 1
      exe "normal mz"
      %s/\s\+$//ge
      exe "normal `z"
    endif
  endfunc "}}}

  func! s:ToggleTrailingWSDeletionFn() abort "{{{
    let g:delete_trailing_ws = !g:delete_trailing_ws
  endfunc "}}}
  command! -nargs=0 ToggleTrailingWSDeletion call s:ToggleTrailingWSDeletionFn()

  func! s:UnsetTrailingWSDeletionFn() abort "{{{
    let g:delete_trailing_ws = 0
  endfunc "}}}
  command! -nargs=0 UnsetTrailingWSDeletion call s:UnsetTrailingWSDeletionFn()

  func! s:SetTrailingWSDeletionFn() abort "{{{
    let g:delete_trailing_ws = 1
  endfunc "}}}
  command! -nargs=0 SetTrailingWSDeletion call s:SetTrailingWSDeletionFn()

  func! s:WSFn(override, force) abort "{{{
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
  endfunc "}}}

  command! -nargs=0 WS call s:WSFn(0, 0)
  command! -nargs=0 WWS call s:WSFn(0, 1)
  command! -nargs=0 XS call s:WSFn(0, 0)
  command! -nargs=0 XXS call s:WSFn(0, 1)

  func! s:ShowVimColors() abort "{{{
    exe '! feh ' . g:VIMRC_PATH . '/' . 'vimrc-res/vimcolors.png &'
  endfunction "}}}
  command! ShowVimColors call s:ShowVimColors()

  func! s:EditColorScheme(scheme) abort "{{{
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
  endfunction "}}}
  command! -nargs=1 EditColorScheme call s:EditColorScheme(<q-args>)

  func! Reduce(ffn, list) abort "{{{
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
  endfunction "}}}

  func! s:PrintLine() abort "{{{
    exe 'echo ''' . substitute(getline('.'), '^\s\+\|\s\+$', '', '') . ''''
  endfunction "}}}
  command! -nargs=0 PrintLine call s:PrintLine()

  func! s:ToDoBack() abort "{{{
      silent exe '.-1r ! tail -n 1 is.done' | silent exe 'silent :! sed -i "\$ d" is.done'
  endfunction "}}}

  func! g:SetSpecificMaps() abort "{{{
    if (expand('%:t')) == 'to.do'
      nnoremap <silent> <F5> :exe ':! echo "' . getline('.') . '" >> is.done'<CR>"_dd
      nnoremap <silent> <F6> :call <sid>ToDoBack()<CR>
    endif
  endfunction "}}}

  func! g:Tabularize(range, ...) abort "{{{
    let range = a:range
    let args = copy(a:000)
    let formatters = map(copy(args), 'shellescape(''%s'', 1) . v:val')
    let cols = map(range(len(copy(args))), '''$'' . string(v:val+1)')
    exec(range . '!awk ''{printf "' . join(formatters, ', ') . '\n", ' . join(cols, ', ') . '}''')
  endfunction "}}}

  func! s:AddToDo(todo) abort "{{{
    let filename = expand('%')
    exec '! echo ' . filename . ': ' . shellescape(a:todo, 1) . ' >> ~/to.do'
  endfunction "}}}

  command! -nargs=1 TODO call s:AddToDo(<q-args>)

  func! s:LoadSession(session) abort "{{{
    let session = substitute(a:session, '\(\.vim$\|^[^/]*/\)', '', 'g') . '.vim'
    silent exe 'so ' . g:SESSION_PATH . '/' . session
    echo 'loading session ' . session
    let s:current_session = session
    wincmd t
    wincmd q
    NERDTree
    wincmd =
  endfunc "}}}
  command! -nargs=1 LoadS call s:LoadSession(<q-args>)

  func! s:GetSessionName() abort "{{{
    return s:current_session
  endfunc "}}}
  command! -nargs=0 GetS echo s:GetSessionName()

  func! s:SaveSession(bang, ...) abort "{{{
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
  endfunc "}}}
  command! -nargs=? -bang SaveS call s:SaveSession(<bang>0, <q-args>)

  " func! s:EnqueueSessions()
  "   let path = g:SESSION_PATH
  "   for i in

  func! s:ListSessionsInShell() abort "{{{
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
  endfunc "}}}
  command! -nargs=0 ListS call s:ListSessionsInShell()

  func! s:RemoveSession(session) abort "{{{
    let path = g:SESSION_PATH
    let session = substitute(a:session, '\(\.vim$\|^[^/]*/\)', '', 'g') . '.vim'
    let file = shellescape(path . '/' . session)
    let error = system('rm ' . file . ' 2> /dev/null; echo $?')
    if !error
      echo "removed session '" . a:session . "'"
    else
      echo "no file found for session '" . a:session . "'"
    endif
  endfunc "}}}

  command! -nargs=1 RemoveS call s:RemoveSession(<f-args>)

  command! -nargs=0 AC call system("ACPI")

  func! Map(Fn, li, ...) abort "{{{
    let new_li = []
    if a:0
      if a:0 != 1
        throw 'ArgumentError: Map() expects at most 3 arguments, '.a:0.' given'
      elseif !IsDict(a:1)
        throw 'TypeError: Map() expects optional third argument to be dict'
      else
        let d = a:1
      endif
    else
      let d = {}
    endif
    for el in a:li
      call add(new_li, call(a:Fn, [el], d))
    endfor
    return new_li
  endfunc "}}}

  func! Reduce(Fn, li, ...) abort "{{{
    let li = a:li
    let accu = a:0 ? a:1 : remove(li, 0)
    let d = a:0 == 2 ? a:2 : {}
    for el in li
      let accu = call(a:Fn, [accu, remove(li, 0)], d)
    endfor
    return accu
  endfunc "}}}

  func! Filter(Fn, li, ...) abort "{{{
    let new_li = []
    if a:0
      if a:0 != 1
        throw 'ArgumentError: Filter() expects at most 3 arguments, '.a:0.' given'
      elseif !IsDict(a:1)
        throw 'TypeError: Filter() expects optional third argument to be dict'
      else
        let d = a:1
      endif
    else
      let d = {}
    endif
    for el in a:li
      if call(a:Fn, [el], d)
        call add(new_li, el)
      endif
    endfor
    return new_li
  endfunc "}}}

  func! Inc(val) abort "{{{
    return a:val + 1
  endfunc "}}}

  func! Dec(val) abort "{{{
    return a:val - 1
  endfunc "}}}

  func! Identity(Obj) abort "{{{
    return a:Obj
  endfunc "}}}
    func! s:ToDoBack() abort "{{{
        silent exe '.-1r ! tail -n 1 is.done' | silent exe 'silent :! sed -i "\$ d" is.done'
    endfunction "}}}

  func! GetBufferNameFromQuickfix(qf_line) abort "{{{
    let bufnr = a:qf_line.bufnr
    return bufname(bufnr)
  endfunc "}}}

  func! StartsWith(str, start) abort "{{{
    let _len = len(a:start)
    if !Bool(_len)
      return 1
    else
      return a:str[0:_len-1] == a:start
    endif
  endfunc "}}}

  func! EndsWith(str, end) abort "{{{
    let _len = len(a:end)
    if !Bool(_len)
      let res = g:true
    else
      let res = a:str[- _len : ] == a:end
    endif
    return res
  endfunc "}}}

  func! FindProjectRoot(...) abort "{{{
    let s:_project_files = a:0 == 2 ? a:2 : s:default_project_files
    let cur_dir = fnamemodify(a:0 ? a:1 : ".",
      \                       ":p:h")
    if cur_dir == "/"
      return ""
    else
      func! BaseName(path) abort "{{{
        return fnamemodify(a:path, ":t")
      endfunc "}}}

      func! IsProjectFile(file) abort "{{{
        return Contains(s:_project_files, a:file)
      endfunc "}}}

      let result = Filter('IsProjectFile',
        \                  Map('BaseName',
        \                      split(glob(cur_dir . "/*"))))

      return Bool(result) ? cur_dir : FindProjectRoot(fnamemodify(cur_dir, ":h"),
            \                                         s:_project_files)
    endif
  endfunc "}}}

  func! IsInt(Obj) abort "{{{
    return type(a:Obj) == g:int
  endfunc "}}}

  func! IsString(Obj) abort "{{{
    return type(a:Obj) == g:str
  endfunc "}}}

  func! IsDict(Obj) abort "{{{
    return type(a:Obj) == g:dict
  endfunc "}}}

  func! IsFloat(Obj) abort "{{{
    return type(a:Obj) == g:float
  endfunc "}}}

  func! IsFunction(Obj) abort "{{{
    return type(a:Obj) == g:funcref
  endfunc "}}}

  func! IsList(Obj) abort "{{{
    return type(a:Obj) == g:list
  endfunc "}}}

  func! IsClassDefined(ObjectName) abort "{{{
    return Contains(s:classes, a:ObjectName)
  endfunc "}}}

  func! GetClass(ObjectName) abort "{{{
    let ObjectName = a:ObjectName
    if !IsClassDefined(a:ObjectName)
      throw 'TypeError: variable is not a valid class identifier'
    else
      let Result = s:DeepcopyFields(s:classes[ObjectName])
    endif
    return Result
  endfunc "}}}

  func! IsObject(Obj) abort "{{{
    let Obj = a:Obj
    return  IsDict(Obj) &&
          \ Contains(Obj, 'Class') &&
          \ Contains(Obj, 'ClassName') &&
          \ IsFunction(Obj.Class) &&
          \ IsFunction(Obj.ClassName) &&
          \ IsClassDefined(Obj.ClassName())
  endfunc "}}}

  func! Type(Var) abort "{{{
    let Var = a:Var
    if IsInt(Var)
      let res = g:int
    elseif IsFloat(Var)
      let res = g:float
    elseif IsString(Var)
      let res = g:str
    elseif IsList(Var)
      let res = g:list
    elseif IsFunction(Var)
      let res = g:funcref
    elseif IsObject(Var)
      let res = g:object
    else
      let res = g:dict
    endif
    return res
  endfunc "}}}

  func! First(li) abort "{{{
    return a:li[0]
  endfunc "}}}

  func! Last(li) abort "{{{
    return a:li[-1]
  endfunc "}}}

  func! MatchesRegEx(str, pattern) abort "{{{
    return matchstr(a:str, a:pattern) != ''
  endfunc "}}}

  func! s:GetGitTopLevelDirFromRevParse(curdir) abort "{{{
    let toplevel = system('git -C ' . a:curdir . ' rev-parse --show-toplevel')
    return toplevel
  endfunc "}}}

  func! GGG() abort "{{{
    return s:GetGitTopLevelDir()
  endfunc "}}}

  func! GGGR(curdir) abort "{{{
    return s:GetGitTopLevelDirFromRevParse(a:curdir)
  endfunc "}}}

  func! s:GetGitTopLevelDir() abort "{{{
    let bufdir = expand('%:p:h')
    if bufdir[0] == '/'
      let toplevel = s:GetGitTopLevelDirFromRevParse(bufdir)
      if v:shell_error == 0
        return toplevel
      endif
    endif

    let curdir = getcwd()
    let toplevel = s:GetGitTopLevelDirFromRevParse(curdir)
    if v:shell_error != 0
      echoerr "[ERROR] current working dir is not part of a git repository"
    else
      return toplevel
    endif
  endfunc "}}}

  command! -nargs=0 GWD echo s:GetGitTopLevelDir()

  func! s:AgInGitRepository(pattern) abort "{{{
    let search_cmd = 'vimgrep'
    if exists(':Ag') == 2
      let search_cmd = 'Ag'
    endif
    exe search_cmd . '! ' .  a:pattern . ' ' . s:GetGitTopLevelDir()
  endfunc "}}}

  command! -nargs=1 AG call s:AgInGitRepository(<q-args>)

  func! s:NERDTreeOpenGitRoot() abort "{{{
    exe ':NERDTree ' . s:GetGitTopLevelDir()
  endfunc "}}}

  func! s:NERDTreeReopenWithGitRoot() abort "{{{
    call s:NERDTreeOpenGitRoot()
    wincmd p
    exe ':NERDTreeFind'
  endfunc "}}}

  command! -nargs=0 NERDTreeGitRoot call s:NERDTreeOpenGitRoot()
  command! -nargs=0 NERDTreeGitRootFind call s:NERDTreeReopenWithGitRoot()

  if !exists("s:current_colorscheme")
    let s:current_colorscheme = ""
  endif

  func! GetColorscheme() abort "{{{
" return current colorscheme
"
" GetColorscheme: 0 -> str

    return s:current_colorscheme
  endfunc "}}}

  func! GetColors() abort "{{{
    return GetColorscheme()
  endfunc "}}}

  func! GetTypeName(type) abort "{{{
" return name of type
"
" GetTypeName: arb -> str

    let _type = type(a:type)
    return s:type_dict[_type]
  endfunc "}}}

  func! TypeToName(type) abort "{{{
    if type(a:type) != g:int
      echoerr "wrong type of argument. got " GetTypeName(a:type) "while expecting int"
      throw g:arg_err
    endif
    if a:type < 0 || a:type > 5
      echoerr "argument '".a:type."' is not a type. types are in range [0, 5]"
      throw g:arg_err
    endif
    return s:type_dict[a:type]
  endfunc "}}}

  func! SetColorscheme(...) abort "{{{
" set colorscheme and override background and search colors
"
" SetColorscheme: 0 ^ str -> bool
" returns true if changed else false

    if a:0 == 0
      let colorscheme = g:default_colorscheme
      lockvar colorscheme
    elseif a:0 == 1
      let colorscheme = a:1
      lockvar colorscheme
      let _type = type(colorscheme)
      if _type != g:str
        echoerr "wrong type for first argument. got" GetTypeName(_type) "while expecting str"
        throw g:arg_err
      endif
    else
      echoerr "wrong number of arguments. got" a:0 "while expecting 0 or 1"
      throw g:arg_err
    endif

    if GetColorscheme() != colorscheme
      let s:current_colorscheme = colorscheme
      exe "colorscheme" colorscheme
      for opt in ["Normal", "NonText"]
        exe "hi " . opt . " ctermbg=none"
      endfor
      hi Normal ctermbg=none
      hi Search cterm=reverse

      return g:true
    else
      return g:false
    endif

  endfunc "}}}

  function LoadColorschemeFromDict(d) abort "{{{
    for [attr, vals] in d
      exe 'hi' attr join(values(map(copy(vals), 'join([v:key, v:val], "=")')), " ")
    endfor
  endfunc "}}}

  func! GetMd5OfFile(file) abort "{{{
    return split(system("md5sum ".a:file))[0]
  endfunc "}}}

  func! GetFuncRef(Fn) abort "{{{
    if type(a:Fn) == type("")
      return function(a:Fn)
    elsf
      return a:Fn
    endif
  endfunc "}}}

  func! True(...) abort "{{{
    return 1
  endfunc "}}}

  func! False(...) abort "{{{
    return 0
  endfunc "}}}

  func! SplitString(s) abort "{{{
    let res = []
    for i in range(len(a:s))
      call add(res, a:s[i])
    endfor
    return res
  endfunc "}}}

  func! GetPassword(...) abort "{{{
    let type = a:0 ? a:1 : 'alnum'
    if type == 'alnum'
      return strpart(system('apg -m 40 -x 40 -a 0 -s -n 1 2>/dev/null |tail -n 1'), 0, 40)
    elseif
      echoerr 'type ' . type . ' is not supported yet'
      return ''
    endif
  endfunc "}}}
endif

func! SetOpt(opt, val, ...) abort "{{{
  exe 'set '.a:opt."=".a:val
  if a:0
    return a:1
  else
    return 0
  endif
endfunc "}}}

func! GetCtrlPCommand(...) abort "{{{
  let cmd = 'ag %s -l --nocolor --hidden --ignore-case --ignore ".git" --ignore ".hg" --ignore ".svn" -g ""'
  if a:0
    let data = a:1
    if exists('data.noVcsIgnore') && !data.noVcsIgnore
      let cmd = cmd . ' -U'
    endif
  endif
  return cmd
endfunc "}}}



" vim: ft=vim

