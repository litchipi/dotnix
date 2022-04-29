colorscheme tokyonight

highlight SignColumn guibg=None

set termguicolors     " enable true colors support
syntax on

let g:tokyonight_style = 'night' " available: night, storm
let g:tokyonight_enable_italic = 1
let g:tokyonight_transparent_background = 1

" TODO          Get the theme from nix-generated colors

let theme_comments='#367e6f'

highlight ColorColumn guibg=None
highlight Comment guifg=theme_comments

highlight LineNr guifg=#149477
highlight CursorLineNR gui=bold guifg=#0bd4a7
highlight Pmenu ctermbg=8 guibg=#606060
highlight PmenuSel ctermbg=1 guifg=#dddd00 guibg=#1f82cd
highlight PmenuSbar ctermbg=0 guibg=#d6d6d6
highlight VertSplit gui=NONE guifg=NONE guibg=NONE

highlight Search guibg=NONE guifg=#ffc453 gui=underline,bold
highlight QuickFixLine gui=NONE guibg=NONE guifg=#ffc453
highlight TODO guibg=NONE guifg=#dd5dc4 gui=underline,bold

highlight CocHintSign guifg=#006532 gui=italic
