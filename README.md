# Oniwabandana

Oniwabandana is a vim plugin for finding files. It brings up a list of all the files in your current directory or source tree and then you can type words to filter what is shown. If you hit space then the next word becomes another filter (or you can hit two spaces to use an actual space). It tries to show the files in a smart order. When you've found the right file you can hit enter to open it, Ctrl-T to open it in a new tab or Ctrl-C to close the completion list (the keys are configurable).

It doesn't need any C compilation step but it needs vim to be built with ruby support (vim --version | grep '+ruby').

Type :Oniwabandana (or :On&lt;tab&gt; :P).

## TODO
* Highlight matching strings in matches window.
* Allow configurable file sources (currently uses git ls-files which gets files in git index recursively from current directory)

## Configuration

The defaults are shown:
```
" Maximum height of file selection box.
let g:oniwa_height=10

" Perform case-insensitive matching.
let g:oniwa_case_sensitive=0

" Keys bindings when match window is open.
let g:oniwa_tabopen="<c-t>"
let g:oniwa_open="<cr>"
" If the current buffer is unmodified and unnamed then replace it, otherwise
" open a new tab
let g:oniwa_open_smart="<c-o>"
let g:oniwa_backspace="<c-h>"  " in addition to backspace key
let g:oniwa_close="<c-c>"

" This is a vim setting that Oniwabandana uses to filter matches.
set wildignore="*.png,*.gif"
```

This would make Oniwabandana easier to use:
```
:map <leader>o :Oniwabandana<CR>
```

By default &lt;leader&gt; is backslash in vim so pushing "\o" would open Oniwabandana.

## Installation

You could install it with [pathogen](https://github.com/tpope/vim-pathogen) or [vundle](https://github.com/gmarik/Vundle.vim).

[Ban Ban](http://wikimoon.org/index.php?title=Oniwabandana).

## Dependencies
 * [GlobalOptions](http://www.vim.org/scripts/script.php?script\_id=4414)
