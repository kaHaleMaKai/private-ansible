set tabstop=4
set shiftwidth=4
set smarttab
set softtabstop=4
set tabstop=8
set autoindent
set expandtab

function! s:CreateNewJavaEntity(...)
  let name = expand('<cword>')
  let package = Bool(a:0) ? a:1 : ''
  let full_name = []
  if Bool(package)
    call add(full_name, package)
  endif
  call add(full_name, name)
  let type = a:0 == 2 ? a:2 : 'class'
  exe 'JavaNew' type join(full_name, ".")
  if expand("%:t") == name . ".java"
    call InsertAuthorAndDate()
  endif
endfunc

function! InsertAuthorAndDate(...)
  let date = strftime("%F")
  let linenr = Bool(a:0) ? a:1 : line(".") + 1
  let author = a:0 == 2 ? a:2 : "lars"
  call append(linenr, " */")
  call append(linenr, " * Created by " . author . " on " . date . ".")
  call append(linenr, "/**")
  w
endfunc

function! IsNotAJavaTest(qf_line)
  return !StartsWith(GetBufferNameFromQuickfix(a:qf_line),
        \            "test/")
endfunc

"function! s:GetPackage()
  "let cur_linenr = line(".")
  "for linenr in range(cur_linenr, 1, -1)
    "let line = getline(linenr)
    "let m = matchend(line, "^\s*package\s*")
    "if match > -1
      "let package = matchstr(line, "[a-z_.]"), m + 1)
      "return package
    "endif
  "endfor
  "return ""
"endfunc

command! -nargs=? Eclimd :!eclimd <args>
command! -nargs=0 EclimdNewProject :exe 'ProjectCreate' FindProjectRoot() ' -n java'
command! -nargs=* New :call <sid>CreateNewJavaEntity(<q-args>)
command! -nargs=0 FilterJavaSrcInQuickFix :call setqflist(Filter('IsNotAJavaTest', getqflist()))

nnoremap <silent> <buffer> gi :JavaImport<cr>
nnoremap <silent> <buffer> K :exe 'JavaDocPreview'\|wincmd p<CR>
nnoremap <silent> <buffer> gK :JavaSearch<CR>
nnoremap <silent> <buffer> <cr> :JavaSearchContext<cr>
nnoremap <silent> <buffer> gw :New<CR>
nnoremap <silent> <buffer> gqF :FilterJavaSrcInQuickFix<CR>
nnoremap <silent> gqfj :FilterJavaSrcInQuickFix<CR>
nnoremap <silent> <buffer> gV :Validate<CR>

let container = {"use_custom_completion": 0}

function container.SetCustomCompletion() dict
  set completefunc=CallCompletion
  let self.use_custom_completion = 2
  return 1
endfunc

function container.UseCustomCompletion() dict
  return Bool(self.use_custom_completion)
endfunc

function container.UnsetCustomCompletion() dict
  let self.use_custom_completion = 0
endfunc

if !exists("Completion.fts.java")
  let java_completion = CompletionObject.New('java')
  call java_completion.ChangeSettings({"sorted": 1,
        \                              "ignore_case": 1,
        \                              "anchored": 1,
        \                              "max_sort_len": 100,
        \                              "max_match_chars": 50,
        \                              "length_penalty": 10})

  call java_completion.AddCustomContainer(container)
  let java_completion.GetFilterPattern = java_completion.GetFuzzyFilterPattern

  function! java_completion.OnRes() dict
    call self.container.UnsetCustomCompletion()
  endfunc

  function! java_completion.UpdateData(...) dict
      let path = Bool(a:0) ? a:1 : FindProjectRoot()
    call system("~/python/gettypes/gettypes.py ".self.GetCompletionDataPath()." ".path)
  endfunc

  function! java_completion.Complete(findstart, base) dict
    if self.container.UseCustomCompletion()
      return self.StdComplete(a:findstart, a:base)
    else
      return eclim#java#complete#CodeComplete(a:findstart, a:base)
    endif
  endfunc

  call Completion.RegisterCompletion(java_completion)

  function! s:GoToTestFile(...)
    let w_mode = Bool(a:0) && Bool(a:1) ? a:1 : 'n'
    let current_file = expand("%:.")
    let class = fnamemodify(current_file, ':t:r') . 'Test'
    let test_file = fnamemodify(substitute(current_file, 'main', 'test', ''),
          \                     ':p:h') . '/' . class . '.java'
    let package_expression = getline(1)
    if !Bool(filewritable(test_file))
      let test_template = s:CreateNewTestFileFromTemplate(class, package_expression)
      call writefile(test_template, test_file)
    endif
    exe 'wincmd ' . w_mode
    exe 'e ' . test_file
  endfunc

  function! s:CreateNewTestFileFromTemplate(class, package_expression)
    let class = a:class
    let package_expression = a:package_expression
    let lines = []
    call add(lines, package_expression)
    call add(lines, "")
    call add(lines, 'import org.junit.Test;')
    call add(lines, 'import static org.junit.Assert.*;')
    call add(lines, "")
    call add(lines, "public class " . class . ' {')
    call add(lines, "")
    call add(lines, '}')
    return lines
  endfunc
endif

inoremap <silent> <buffer> <C-e><C-e> <C-e>
inoremap <expr> <silent> <buffer> <C-e><C-t> (Completion.Container().SetCustomCompletion() ? '<C-x><C-u>' : '')
inoremap <expr> <silent> <buffer> <C-e><F5> (Completion.Ft().ReadCompletionData() ? '' : '')
nnoremap <silent> <buffer> <leader><F5> :call Completion.Ft().ReadCompletionData()<CR>
inoremap <silent> <buffer> <C-c> <C-c>:%TruncateSpaces<CR>

command! -nargs=? GoToTestFile :call <SID>GoToTestFile(<q-args>)
nnoremap <silent> <buffer> gjT :GoToTestFile<CR>
nnoremap <silent> <buffer> gjtn :GoToTestFile n<CR>
nnoremap <silent> <buffer> gjtv :GoToTestFile v<CR>

set completefunc=CallCompletion

if !exists("b:java_vim_autocommands_loaded")
  let b:java_vim_autocommands_loaded = 1
  au BufWrite <buffer> call eclim#lang#UpdateSrcFile('java', 1)
endif
