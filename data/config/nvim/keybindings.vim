
let g:mapleader = '$'

noremap <leader><Space> :nohlsearch<CR>

noremap <leader>z :enew<CR>
noremap <leader>s :Bwipeout<CR>

" Overwrite ?
noremap <leader>d :bnext<CR>
noremap <leader>q :bprevious<CR>

noremap <leader>m :TagbarToggle<CR>
noremap <leader>p :NERDTreeToggle<CR>
noremap <leader>o :call nerdcommenter#Comment("x", "toggle")<CR>
noremap <Tab> <C-w>w

noremap <leader>& :GFiles<CR>
noremap <leader>1 :Files<CR>
noremap <leader>é :Rg<CR>
noremap <leader>f :Buffers<CR>
noremap <leader>c :BCommits<CR>

noremap <A-q> h
noremap <A-s> j
noremap <A-d> l
noremap <A-z> k

noremap <A-a> :bprevious<CR>
noremap <A-e> :bnext<CR>
noremap <A-&> :lnext<CR>
noremap <A-"> :lprevious<CR>

noremap <A-S-z> 5k
noremap <A-S-q> b
noremap <A-S-d> w
noremap <A-S-s> 5j

noremap <A-r> :wincmd c<CR>
noremap <leader>r :vsplit<CR>
noremap <leader>t :split<CR>
noremap <A-f> :ZoomToggle<CR>

if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

nmap <silent> eg <Plug>(coc-diagnostic-prev)
nmap <silent> ag <Plug>(coc-diagnostic-next)

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>i <Plug>(coc-rename)

nnoremap <leader>a :<C-u>CocFzfList diagnostics<CR>
nnoremap <leader>g  :<C-u>CocFzfList commands<CR>
nnoremap <leader>e  :<C-u>CocFzfList outline<CR>
nnoremap <leader>²  :<C-u>CocFzfList symbols<CR>

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

noremap <leader>" :set number!<CR>
