set completeopt=noinsert,menuone,noselect

set noswapfile
set undofile

set shortmess+=c

if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

if &encoding != 'utf-8'
    set encoding=utf-8              "Necessary to show Unicode glyphs
endif

set mouse=a
set shiftwidth=4

set scrolloff=10
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

"set autoindent
"set smartindent
"set tabstop=4
"set softtabstop=4

set number                  " add line numbers
set cc=100

set wildmode=longest,list   " get bash-like tab completions

set clipboard+=unnamedplus
