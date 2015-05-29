if !exists("Completion")
  let Completion = {"fts": {}}

  function! Completion.GetFiletype() dict
    return &ft
  endf

  function! Completion.HasCompletionFor(ft) dict
    return has_key(self.fts, a:ft)
  endfunc

  function! Completion.HasCompletion() dict
    return has_key(self.fts, &ft)
  endfunc

  function! Completion.Complete(findstart, base) dict
    if self.HasCompletion()
      return self.Ft().Complete(a:findstart, a:base)
    else
      return -1
    endif
  endfunc

  function! Completion.RegisterCompletion(completionObject) dict
    let self.fts[a:completionObject.ft] = a:completionObject
  endfunc

  function! Completion.ListCompletions() dict
    return keys(self.fts)
  endfunc

  function! Completion.GetCompletionFor(ft, ...) dict
    if a:1
      if self.HasCompletionFor(a:ft)
        return self.fts[a:ft]
      else
        return a:1
      endif
    else
      return self.fts[a:ft]
    endif
  endfunc

  function! Completion.Ft() dict
    return self.fts[self.GetFiletype()]
  endfunc

  function Completion.Container() dict
    return self.Ft().Container()
  endfunc
endif
