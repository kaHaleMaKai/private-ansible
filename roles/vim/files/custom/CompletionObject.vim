if !exists("CompletionObject")
  let CompletionObject = {"ft": "",
        \                 "data": [],
        \                 "filepath": "",
        \                 "container": {},
        \                 "md5": "",
        \                 "interval": 5,
        \                 "timestamp": "",
        \                 "pattern": "",
        \                 "ignore_case": 0,
        \                 "anchored": 1,
        \                 "sorted": 0,
        \                 "length_penalty": 5,
        \                 "max_sort_len": 25,
        \                 "max_score": -1,
        \                 "max_match_chars": 25}

  function CompletionObject.New(ft, ...) dict
    let d = deepcopy(self)
    let d.ft = a:ft
    call d.SetCurrentTimestamp()
    call d.SetFilepath(Bool(a:0) ? a:1 : "")
    return d
  endfunc

  function CompletionObject.ChangeSettings(d) dict
    for [k, v] in items(a:d)
      let self[k] = v
    endfor
  endfunc

  function CompletionObject.CalcTimestamp() dict
    return str2nr(strftime("%H"))*60 + str2nr(strftime("%M"))
  endfunc

  function CompletionObject.SetCurrentTimestamp() dict
    let self.timestamp = self.CalcTimestamp()
  endfunc

  function CompletionObject.GetTimestamp() dict
    return self.timestamp
  endfunc

  function CompletionObject.SetData(data) dict
    let self.data = a:data
  endfunc

  function CompletionObject.GetFiletype() dict
    return self.ft
  endfunc

  function CompletionObject.GetCompletionDataPath() dict
    return self.filepath
  endfunc

  function CompletionObject.GetMd5() dict
    return self.md5
  endfunc

  function CompletionObject.SetMd5() dict
    let self.md5 = GetMd5OfFile(self.GetCompletionDataPath())
  endfunc

  function CompletionObject.UpdateData() dict
    return -1
  endfunc

  function CompletionObject.SetFilepath(filepath) dict
    let filepath = Bool(a:filepath)
          \        ? a:filepath
          \        : "~/.vim/completion/".self.ft."-completion-data"
    let self.filepath = expand(filepath, "p")
  endfunc

  function CompletionObject.ReadCompletionData() dict
    call self.UpdateData()
    call self.SetData(readfile(self.filepath))
    call self.SetMd5()
    return 1
  endfunc

  function CompletionObject.UpdateRequired() dict
    if !Bool(self.GetTimestamp()) || !Bool(self.GetMd5())
      return 1
    elseif self.CalcTimestamp() - self.interval > self.GetTimestamp()
      if GetMd5OfFile(self.GetCompletionDataPath()) != self.GetMd5()
        return 1
      else
        return 0
      endif
      return 0
    endif
  endfunc
  function CompletionObject.GetProximityScore(m) dict
    let ps = SplitString(self.pattern)
    let p_idx = 0
    let p_len = len(ps)
    let p = ps[0]
    let ms = SplitString(a:m)
    let m_len = len(ms)
    let score = m_len / self.length_penalty
    let m_len = self.max_match_chars >= m_len || self.max_match_chars <= 0
          \     ? m_len
          \     : self.max_match_chars
    let m_idx = 0
    while m_idx < m_len
      let m = ms[m_idx]
      if p == m
        let score -= p_idx
        let p_idx += 1
        if p_idx == p_len
          break
        else
          let p = ps[p_idx]
        endif
      elseif p ==? m
        let score += m_idx - p_idx*2
        let p_idx += 1
        if p_idx == p_len
          break
        else
          let p = ps[p_idx]
        endif
      endif
      let m_idx += 1
      let score += 1
      if self.max_score > 0 && (score + m_idx-p_idx) >= self.max_score
        let score = self.max_score
        break
      endif
    endwhile
    return score
  endfunc
  function CompletionObject.Comperator(m1, m2) dict
    let score_m1 = self.GetProximityScore(a:m1)
    let score_m2 = self.GetProximityScore(a:m2)
    return score_m1 == score_m2 ? 0 : score_m1 > score_m2 ? 1 : -1
  endfunc
  function CompletionObject.GetFuzzyFilterPattern(base) dict
      let pattern = (self.anchored ? "^" : "")
            \       . join(SplitString(a:base), ".*")
      return pattern
  endfunc
  function CompletionObject.GetStdFilterPattern(base) dict
    let pattern = '^' . a:base
    return pattern
  endfunc
  function CompletionObject.GetFilterPattern(base) dict
    return self.GetStdFilterPattern(a:base) dict
  endfunc
  function CompletionObject.Filter(base) dict
    let res = []
    let pattern = self.GetFilterPattern(a:base)
    if self.ignore_case
      for m in self.data
        if m =~? pattern
          call add(res, m)
        endif
      endfor
    else
      for m in self.data
        if m =~ pattern
          call add(res, m)
        endif
      endfor
    endif
    return res
  endfunc
  function CompletionObject.StdComplete(findstart, base) dict
    if self.UpdateRequired()
      call self.ReadCompletionData()
    endif
    if a:findstart
      let line = getline('.')
      let start = col('.') - 1
      while start > 0 && line[start - 1] =~ '\a'
        let start -= 1
      endwhile
      return start
    else
      let res = self.Filter(a:base)
      if Bool(res)
        if has_key(self, "OnRes")
          call self.OnRes()
        endif
        if Bool(a:base) && self.sorted && (self.max_sort_len <= 0 || len(res) <= self.max_sort_len)
          let self.pattern = a:base
          call sort(res, self.Comperator, self)
        endif
      endif
      return res
    endif
  endfunc

  function CompletionObject.Complete(findstart, base) dict
    return self.StdComplete(a:findstart, a:base)
  endfunc

  function CompletionObject.AddCustomContainer(c) dict
    let self.container = a:c
  endfunc

  function CompletionObject.Container() dict
    return self.container
  endfunc

endif
