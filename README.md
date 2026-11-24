# quarto-slides

Write [reveal.js](https://revealjs.com) decks in Vim with
[Quarto](https://quarto.org). `quarto preview` runs in a pane next to Vim and
reloads the browser on every `:w`.

**Vim or Neovim:** Vim only, tested on 9.1 and newer. It calls Vim-only
functions (`term_start()`, `job_stop()`), so it doesn't work on Neovim.

## Install

Needs `quarto`. The preview opens in a tmux pane inside tmux, or a WezTerm
pane inside WezTerm. Anywhere else it runs in a hidden Vim terminal (`:ls!`
lists it). With [vim-dispatch](https://github.com/tpope/vim-dispatch),
`:SlidesRender` renders into the quickfix list.

```vim
Plug 'vimoured/quarto-slides'
```

## Use

| Command | `<Plug>` mapping | What it does |
| --- | --- | --- |
| `:SlidesPreview` | `<Plug>(quarto-slides-preview)` | Toggle the live preview pane for the current `.qmd`. |
| `:SlidesRender` | `<Plug>(quarto-slides-render)` | Render the final `.html`. |
| `:SlidesOpen` | `<Plug>(quarto-slides-open)` | Open the rendered `.html` in the browser. |
| `:SlidesStop` | | Stop the preview. Quitting Vim stops it too. |

Bind the mappings yourself, for example in `~/.vim/after/ftplugin/quarto.vim`.
Use `after/` because Vim's quarto ftplugin also sources the markdown one, so
its `_p` would win otherwise:

```vim
nmap <buffer> <localleader>p <Plug>(quarto-slides-preview)
nmap <buffer> <localleader>r <Plug>(quarto-slides-render)
nmap <buffer> <localleader>o <Plug>(quarto-slides-open)
```

Set `g:quarto_slides_pane_percent` (default `25`) to change the width of the
preview pane.

A template deck and a `slides` shell command live in
[roumail/quarto-slides](https://github.com/roumail/quarto-slides).

## Tests

The specs in [vim-suite](https://github.com/vimoured/vim-suite) define what it
does: `test/quarto-slides.vim` and `test/quarto-slides-outside-tmux.vim`.
