# quarto-slides

Write [reveal.js](https://revealjs.com) decks in Vim with
[Quarto](https://quarto.org). `quarto preview` runs in the background and
reloads the browser on every `:w`; no window or pane opens for it.

**Vim or Neovim:** Vim only, tested on 9.1 and newer. It calls Vim-only
functions (`job_start()`, `job_stop()`), so it doesn't work on Neovim.

## Install

Needs `quarto`. `:SlidesLog` needs
[vim-draft](https://github.com/vimoured/vim-draft). With
[vim-dispatch](https://github.com/tpope/vim-dispatch), `:SlidesRender` renders
into the quickfix list.

```vim
Plug 'vimoured/vim-draft'
Plug 'vimoured/quarto-slides'
```

## Use

| Command | `<Plug>` mapping | What it does |
| --- | --- | --- |
| `:SlidesPreview` | `<Plug>(quarto-slides-preview)` | Toggle the live preview of the current `.qmd`, running in the background. |
| `:SlidesRender` | `<Plug>(quarto-slides-render)` | Render the final `.html`. |
| `:SlidesOpen` | `<Plug>(quarto-slides-open)` | Open the rendered `.html` in the browser. |
| `:SlidesStop` | | Stop the preview. Quitting Vim stops it too. |
| `:SlidesLog` | | What `quarto preview` has written so far, in a vim-draft scratch. |

Bind the mappings yourself, for example in `~/.vim/after/ftplugin/quarto.vim`.
Use `after/` because Vim's quarto ftplugin also sources the markdown one, so
its `_p` would win otherwise:

```vim
nmap <buffer> <localleader>p <Plug>(quarto-slides-preview)
nmap <buffer> <localleader>r <Plug>(quarto-slides-render)
nmap <buffer> <localleader>o <Plug>(quarto-slides-open)
```

If the preview exits with an error, you get one message saying so; `:SlidesLog`
shows why. The log is a snapshot: run it again to see what came after.

## Tests

The specs in [vim-suite](https://github.com/vimoured/vim-suite) define what it
does: `test/quarto-slides.vim`.
