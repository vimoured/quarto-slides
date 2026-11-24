let s:is_wezterm = ($TERM_PROGRAM ==# 'WezTerm' || !empty($WEZTERM_PANE))
let s:is_tmux = !empty($TMUX)

" The running preview: {'kind': 'tmux'|'wezterm'|'term', 'id': ..., 'file': ...}
let s:preview = {}

function! s:Error(msg) abort
  echohl ErrorMsg
  echom 'quarto-slides: ' . a:msg
  echohl None
endfunction

function! s:WeztermBin() abort
  for l:bin in ['wezterm', 'wezterm.exe']
    if executable(l:bin)
      return l:bin
    endif
  endfor
  return ''
endfunction

" The deck in the current buffer, or '' with an error
function! s:Deck() abort
  let l:file = expand('%:p')
  if l:file !~? '\.qmd$'
    call s:Error('not a .qmd file')
    return ''
  endif
  return l:file
endfunction

" quarto's full path: a pane WezTerm spawns gets WezTerm's PATH, not the shell's
function! s:Quarto() abort
  let l:quarto = exepath('quarto')
  if empty(l:quarto)
    call s:Error('quarto not found on PATH (https://quarto.org/docs/get-started/)')
  endif
  return l:quarto
endfunction

function! s:StartTmux(quarto, file) abort
  let l:cmd = shellescape(a:quarto) . ' preview ' . shellescape(a:file)
  let l:id = trim(system(printf(
        \ 'tmux split-window -d -h -l %d%% -c %s -P -F "#{pane_id}" %s',
        \ g:quarto_slides_pane_percent,
        \ shellescape(fnamemodify(a:file, ':h')),
        \ shellescape(l:cmd))))
  return v:shell_error ? {} : {'kind': 'tmux', 'id': l:id}
endfunction

function! s:StartWezterm(quarto, file) abort
  let l:bin = s:WeztermBin()
  let l:id = trim(system(printf(
        \ '%s cli split-pane --right --percent %d --cwd %s -- %s preview %s',
        \ l:bin,
        \ g:quarto_slides_pane_percent,
        \ shellescape(fnamemodify(a:file, ':h')),
        \ shellescape(a:quarto),
        \ shellescape(a:file))))
  if v:shell_error || l:id !~# '^\d\+$'
    return {}
  endif
  " split-pane focuses the new pane; hand focus back to Vim
  if !empty($WEZTERM_PANE)
    call system(l:bin . ' cli activate-pane --pane-id ' . $WEZTERM_PANE)
  endif
  return {'kind': 'wezterm', 'id': l:id}
endfunction

function! s:StartTerm(quarto, file) abort
  let l:buf = term_start([a:quarto, 'preview', a:file], {
        \ 'hidden': 1,
        \ 'term_name': '__quarto_preview',
        \ 'term_finish': 'close',
        \ 'cwd': fnamemodify(a:file, ':h'),
        \ })
  return l:buf > 0 ? {'kind': 'term', 'id': l:buf} : {}
endfunction

function! quarto_slides#running() abort
  if empty(s:preview)
    return 0
  endif
  if s:preview.kind ==# 'term'
    return bufexists(s:preview.id) && term_getstatus(s:preview.id) =~# 'running'
  elseif s:preview.kind ==# 'tmux'
    " Not display-message -t: for a pane that's gone it falls back to the
    " current one and succeeds
    return index(systemlist("tmux list-panes -a -F '#{pane_id}'"), s:preview.id) >= 0
  endif
  " wezterm: is the pane still in the list?
  let l:panes = system(s:WeztermBin() . ' cli list --format json')
  return !v:shell_error && l:panes =~# '"pane_id":\s*' . s:preview.id . '\>'
endfunction

function! quarto_slides#start() abort
  let l:file = s:Deck()
  let l:quarto = s:Quarto()
  if empty(l:file) || empty(l:quarto)
    return
  endif
  if quarto_slides#running()
    call quarto_slides#stop()
  endif

  let s:preview = {}
  if s:is_tmux
    let s:preview = s:StartTmux(l:quarto, l:file)
  elseif s:is_wezterm && !empty(s:WeztermBin())
    let s:preview = s:StartWezterm(l:quarto, l:file)
  endif
  if empty(s:preview)
    " No multiplexer (or it failed): a hidden Vim terminal, :ls! shows it
    let s:preview = s:StartTerm(l:quarto, l:file)
  endif
  if empty(s:preview)
    call s:Error('could not start quarto preview')
    return
  endif
  let s:preview.file = l:file
  echo 'Slides preview: ' . fnamemodify(l:file, ':t') . ' (' . s:preview.kind . '), :w reloads the browser'
endfunction

function! quarto_slides#stop() abort
  if empty(s:preview)
    return
  endif
  if s:preview.kind ==# 'term'
    if bufexists(s:preview.id)
      call job_stop(term_getjob(s:preview.id))
      silent! execute 'bwipeout!' s:preview.id
    endif
  elseif s:preview.kind ==# 'tmux'
    call system('tmux kill-pane -t ' . s:preview.id)
  else
    call system(s:WeztermBin() . ' cli kill-pane --pane-id ' . s:preview.id)
  endif
  let s:preview = {}
  echo 'Slides preview stopped'
endfunction

function! quarto_slides#toggle_preview() abort
  if quarto_slides#running() && s:preview.file ==# expand('%:p')
    call quarto_slides#stop()
  else
    call quarto_slides#start()
  endif
endfunction

" quarto render into the quickfix list (vim-dispatch), or a terminal split
function! quarto_slides#render() abort
  let l:file = s:Deck()
  let l:quarto = s:Quarto()
  if empty(l:file) || empty(l:quarto)
    return
  endif
  silent update
  if exists(':Dispatch') == 2
    execute 'Dispatch ' . shellescape(l:quarto) . ' render ' . shellescape(l:file)
  else
    execute 'botright terminal ++rows=12 ' . l:quarto . ' render ' . fnameescape(l:file)
    wincmd p
  endif
endfunction

" Open the rendered .html (format: revealjs: output-file: changes its name)
function! quarto_slides#open() abort
  let l:file = s:Deck()
  if empty(l:file)
    return
  endif
  let l:html = fnamemodify(l:file, ':r') . '.html'
  let l:custom = matchstr(join(getline(1, 40), "\n"), '\n\s*output-file:\s*\zs[^\n#]\{-}\ze\s*\(#\|\n\)')
  if !empty(l:custom)
    let l:html = fnamemodify(l:file, ':h') . '/' . trim(l:custom, '"''')
  endif
  if !filereadable(l:html)
    call s:Error(fnamemodify(l:html, ':t') . ' not rendered yet; render first')
    return
  endif
  if has('mac')
    let l:opener = 'open'
  elseif get(g:, 'is_wsl', 0) && executable('wslview')
    let l:opener = 'wslview'
  elseif has('win32')
    let l:opener = 'start ""'
  else
    let l:opener = 'xdg-open'
  endif
  call system(l:opener . ' ' . shellescape(l:html) . (has('win32') ? '' : ' &'))
endfunction
