set sessionoptions-=help
set sessionoptions-=options
set sessionoptions-=blank

if argc() == 0
    let createdir = system('mkdir -p $HOME/.cache/nvim/sessions')
    let g:sessionf = expand('$HOME/.cache/nvim/sessions/'.trim(system('echo "$PWD"|sha256sum|cut -d " " -f 1')))
    if filereadable(sessionf)
        au VimEnter * exe ":source ".sessionf
:   endif
    au BufWritePost * exe ":mksession! ".sessionf
    au VimLeave * exe ":mksession! ".sessionf
end

autocmd InsertLeave * write
autocmd BufWinEnter * filetype detect
autocmd VimEnter * filetype detect

" autocmd User CocOpenFloat call nvim_win_set_config(g:coc_last_float_win, {'relative': 'editor', 'row': 1, 'col': 130})
