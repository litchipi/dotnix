
" OcaMl configuration

if executable('opam')
  let g:opamshare=substitute(system('opam config var share'),'\n$','','''')
  if isdirectory(g:opamshare."/merlin/vim")
    execute "set rtp+=" . g:opamshare."/merlin/vim"
  endif
endif
