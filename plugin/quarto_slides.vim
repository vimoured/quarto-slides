" quarto-slides: write reveal.js decks in Vim. `quarto preview` runs in the
" background and reloads the browser on every :w; :SlidesLog shows its output.
if exists('g:loaded_quarto_slides')
  finish
endif
let g:loaded_quarto_slides = 1

command! SlidesPreview call quarto_slides#toggle_preview()
command! SlidesStop call quarto_slides#stop()
command! SlidesLog call quarto_slides#log()
command! SlidesRender call quarto_slides#render()
command! SlidesOpen call quarto_slides#open()

" <Plug> mappings; no keys are bound here (see README)
nnoremap <silent> <Plug>(quarto-slides-preview) <Cmd>call quarto_slides#toggle_preview()<CR>
nnoremap <silent> <Plug>(quarto-slides-render) <Cmd>call quarto_slides#render()<CR>
nnoremap <silent> <Plug>(quarto-slides-open) <Cmd>call quarto_slides#open()<CR>

augroup quarto_slides
  autocmd!
  " Don't leave a preview server behind. Only once the autoload file is in:
  " before that nothing runs, and at exit it may no longer be found
  autocmd VimLeavePre * if exists('*quarto_slides#stop') | call quarto_slides#stop() | endif
augroup END
