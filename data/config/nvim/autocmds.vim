
" let g:session_default_name = fnamemodify(getenv('PWD'), ':p')
" let g:session_autosave = 'yes'
" let g:session_autoload = 'yes'

set sessionoptions-=help
set sessionoptions-=options
set sessionoptions-=blank

if argc() == 0 
    " TODO      Fix session auto-write
    " au BufWritePost * exe ":mksession! ".fnamemodify(getenv('PWD'), ':p')
    " au VimEnter * exe ":source ".fnamemodify(getenv('PWD'), ':p')
    " au VimLeave * exe ":mksession! ".fnamemodify(getenv('PWD'), ':p')
end

autocmd InsertLeave * write
autocmd BufWinEnter * filetype detect
autocmd VimEnter * filetype detect
autocmd BufWritePost * GitGutter

autocmd User CocOpenFloat call nvim_win_set_config(g:coc_last_float_win, {'relative': 'editor', 'row': 1, 'col': 130})
