" The running preview: {'job': ..., 'file': ...}. Its output goes to s:log,
" kept after it ends until the next preview starts
let s:preview = {}
let s:log = ''

function! s:Error(msg) abort
  echohl ErrorMsg
  echom 'quarto-slides: ' . a:msg
  echohl None
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

function! s:Quarto() abort
  let l:quarto = exepath('quarto')
  if empty(l:quarto)
    call s:Error('quarto not found on PATH (https://quarto.org/docs/get-started/)')
  endif
  return l:quarto
endfunction

" Only the running preview's exit is news: one stopped or replaced isn't
function! s:Exited(job, status) abort
  if empty(s:preview) || s:preview.job isnot# a:job
    return
  endif
  let s:preview = {}
  if a:status != 0
    call s:Error('quarto preview exited (' . a:status . '), :SlidesLog shows why')
  endif
endfunction

function! quarto_slides#running() abort
  return !empty(s:preview) && job_status(s:preview.job) ==# 'run'
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

  let s:log = tempname()
  let l:job = job_start([l:quarto, 'preview', l:file], {
        \ 'cwd': fnamemodify(l:file, ':h'),
        \ 'in_io': 'null',
        \ 'out_io': 'file', 'out_name': s:log,
        \ 'err_io': 'out',
        \ 'exit_cb': function('s:Exited'),
        \ })
  if job_status(l:job) !=# 'run'
    call s:Error('could not start quarto preview')
    return
  endif
  let s:preview = {'job': l:job, 'file': l:file}
  echo 'Slides preview: ' . fnamemodify(l:file, ':t') . ', :w reloads the browser'
endfunction

function! quarto_slides#stop() abort
  if empty(s:preview)
    return
  endif
  let l:job = s:preview.job
  let s:preview = {}
  call job_stop(l:job)
  echo 'Slides preview stopped'
endfunction

function! quarto_slides#toggle_preview() abort
  if quarto_slides#running() && s:preview.file ==# expand('%:p')
    call quarto_slides#stop()
  else
    call quarto_slides#start()
  endif
endfunction

" What quarto preview has written so far, in a vim-draft scratch
function! quarto_slides#log() abort
  if empty(globpath(&runtimepath, 'autoload/roumail_draft.vim', 1))
    call s:Error(':SlidesLog needs vim-draft, which is not installed')
    return
  endif
  if empty(s:log) || !filereadable(s:log)
    call s:Error('no preview has run yet')
    return
  endif
  execute 'ScratchBuf' fnameescape(s:log)
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
