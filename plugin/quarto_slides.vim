" quarto-slides: write reveal.js decks in Vim. `quarto preview` runs in a
" WezTerm or tmux pane next to Vim (or a hidden Vim terminal) and reloads the
" browser on every :w.
if exists('g:loaded_quarto_slides')
  finish
endif
let g:loaded_quarto_slides = 1

" Width of the preview pane, in percent
let g:quarto_slides_pane_percent = get(g:, 'quarto_slides_pane_percent', 25)

command! SlidesPreview call quarto_slides#toggle_preview()
command! SlidesStop call quarto_slides#stop()
command! SlidesRender call quarto_slides#render()
command! SlidesOpen call quarto_slides#open()

" <Plug> mappings; no keys are bound here (see README)
nnoremap <silent> <Plug>(quarto-slides-preview) <Cmd>call quarto_slides#toggle_preview()<CR>
nnoremap <silent> <Plug>(quarto-slides-render) <Cmd>call quarto_slides#render()<CR>
nnoremap <silent> <Plug>(quarto-slides-open) <Cmd>call quarto_slides#open()<CR>

augroup quarto_slides
  autocmd!
  " Don't leave a preview server behind
  autocmd VimLeavePre * call quarto_slides#stop()
augroup END
