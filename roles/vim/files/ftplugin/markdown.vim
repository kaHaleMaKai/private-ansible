set tabstop=2
set shiftwidth=2
set smarttab
set softtabstop=2
set tabstop=8
set autoindent
set expandtab

"override automatic trimming of trailing whitespace
func! DeleteTrailingWS()
endfunc

if !exists("s:md_loaded")
  func s:AddNewLine() range
    let first = a:firstline
    let last = a:lastline
    let reg = @/

    exe first.",".last."s/^\s*//"
    exe first.",".last."s/^  \+/  /"
    let @/ = reg

    if first == last
      normal! +
    endif
  endfunc

  func s:RemoveTrailingWS() range
    let first = a:firstline
    let last = a:lastline
    let reg = @/

    exe first.",".last."s/^ \+//"
    let @/ = reg

    if first == last
      normal! +
    endif
  endfunc

  func s:Underline(character)
    let cur_linenr = line(".")
    let cur_line = getline(cur_linenr)
    let cur_line_length = len(cur_line)
    let next_line = getline(cur_linenr + 1)
    let next_line_length = len(next_line)
    if cur_line_length == next_line_length && match(next_line, "^".a:character."*$") > -1
      return 1
    else
      let cursor_pos = getpos(cur_linenr)
      call s:RemoveUnderline()
      normal! o
      normal! |
      exe 'normal! ' . cur_line_length . 'i' . a:character
      call cursor(cursor_pos[1], cursor_pos[2])
      return 0
    endif
  endfunc

  func s:RemoveUnderline()
    let cur_linenr = line(".")
    let last_linenr = line("$")
    if cur_linenr != last_linenr
      let cur_line_length = len(getline(cur_linenr))
      let next_line = getline(cur_linenr + 1)
      let next_line_length = len(next_line)
      if cur_line_length == next_line_length && (match(next_line, "^=*$") > -1 || match(next_line, "^-*$") > -1)
        let cursor_pos = getpos(cur_linenr)
        normal! jdd
        call cursor(cursor_pos[1], cursor_pos[2])
      endif
    endif
    return 0
  endfunc

  let s:md_loaded = 1
endif

nnoremap <buffer><silent> <space> :call <sid>AddNewLine()<CR>
nnoremap <buffer><silent> <bs> :call <sid>RemoveTrailingWS()<CR>
nnoremap <buffer><silent> cu= :call <sid>Underline("=")<CR>
nnoremap <buffer><silent> cu- :call <sid>Underline("-")<CR>
nnoremap <buffer><silent> du :call <sid>RemoveUnderline()<CR>
nnoremap <silent> <buffer> <F5> :RevealIt md<CR>
