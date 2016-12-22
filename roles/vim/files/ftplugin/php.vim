set tabstop=4
set shiftwidth=4
set smarttab
set softtabstop=4
set tabstop=8
set autoindent
set noexpandtab

set includeexpr=substitute(v:fname,'^/','','')

if exists(':Make') == 2
  augroup phpCtags
    au!
    au BufWrite,BufWritePre *.php call s:UpdatePhpCtags()
  augroup EMD
endif

func! s:UpdatePhpCtags() abort "{{{
  let curDir = getcwd()
  let pid = getpid()
  let lockfile = '/tmp/php-ctags-'.pid.'.lock'
  if !filereadable(lockfile)
    call system('touch '.lockfile)
    Glcd
    silent exe 'Start! ctags -R --fields=+aimlS --languages=php -f .new-tags && cp .new-tags .copy-of-new-tags && mv .copy-of-new-tags tags && rm '.lockfile
    exe 'lcd '.curDir
  endif
endfunc "}}}

nnoremap <buffer> <silent> <F9> :call <SID>UpdatePhpCtags()<CR>
inoremap § $this
inoremap ä ->
inoremap ł $this->log->

let php_sql_query=1
