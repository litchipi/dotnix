" Whitespace
autocmd BufWritePre * StripWhitespace

" Git
autocmd BufWritePost * GitGutter

" IndentLine
let g:indentLine_setColors = 1
let g:indentLine_color_term = 1
let g:indentLine_char = '┊'

" LSP
let g:lsp_fold_enabled = 0
let g:lsp_diagnostics_enabled = 0         " disable diagnostics support

" AIRLINE (STATUS BAR & THEME)
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#branch#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#syntastic#enabled = 1

" NEOFORMAT (FORMATTING)
let g:neoformat_basic_format_align = 1
let g:neoformat_basic_format_retab = 1
let g:neoformat_basic_format_trim = 1

" NERD Commenter
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = {'c': { 'left': '//' }, 'haskell': {'left':'--'}}

set termguicolors
lua require'colorizer'.setup()
