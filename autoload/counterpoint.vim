" counterpoint.vim - cycle between file counterparts
" Maintainer: Josh Petrie <http://joshpetrie.net>
" Version:    1.1.1

function! <SID>RemoveDuplicates(subject)
  let deduplicated = {}
  for item in a:subject
    let deduplicated[item] = ""
  endfor
  return sort(keys(deduplicated))
endfunction

function! <SID>PrepareSearchPaths(paths, root)
  let results = []
  for path in a:paths
    let result = simplify(a:root . "/" . path)
    let result = fnamemodify(result, ":p")
    let result = substitute(result, "\\\\$", "", "")
    call add(results, result)
  endfor
  return <SID>RemoveDuplicates(results)
endfunction

function! <SID>IsCounterpartExcluded(counterpart)
  for exclusion in g:counterpoint_exclude_patterns
    if a:counterpart =~ exclusion
      return 1
    endif
  endfor
  return 0
endfunction

function! counterpoint#PeekCounterpart(amount)
  let currentFile = expand("%:t")
  if len(currentFile) <= 0
    return ""
  endif

  let parts = split(currentFile, "[.]")
  if g:counterpoint_depth <= 0
    let root = parts[0]
  else
    let root = join(parts[0:-g:counterpoint_depth - 1], ".")
  endif

  " Restore the leading dot, if it existed.
  if currentFile[0] == "."
    let root = "." . root
  endif

  " Prepare search paths.
  let paths = copy(g:counterpoint_search_paths)
  call add(paths, ".")
  let paths = <SID>PrepareSearchPaths(paths, expand("%:h"))

  " Collect the potential counterparts, filter out anything that matches any
  " supplied exclusion patterns, remove any duplicates, and then cycle.
  let results = globpath(join(paths, ","), root . ".*")
  let counterparts = split(results)
  let counterparts = filter(counterparts, "!<SID>IsCounterpartExcluded(v:val)")
  let counterparts = <SID>RemoveDuplicates(counterparts)
  if len(counterparts) <= 1
    return ""
  endif

  let currentPath = expand("%:p")
  let index = 0
  for counterpart in counterparts
    if currentPath == fnamemodify(counterpart, ":p")
      return fnamemodify(counterparts[(index + a:amount) % len(counterparts)], ":~:.")
    endif
    let index += 1
  endfor

  return ""
endfunction

function! counterpoint#CycleCounterpart(amount, reuse, command)
  let result = counterpoint#PeekCounterpart(a:amount)
  if len(result) == 0
    echo "No counterpart available."
  else
    if a:reuse == "!"
      let window = bufwinnr(result)
      if window >= 0
        execute window . "wincmd w"
        return
      endif
    endif

    let command = a:command
    if len(command) == 0
      let command = "edit"
    endif

    execute command . " " . result
  endif
endfunction
