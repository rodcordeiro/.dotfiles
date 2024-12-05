"......................................................................ARQUIVO
" Sai fora na marra!
imap <F12> <esc>:wqa!<cr>
 map <F12> :wqa!<cr>

set nu
set aw


call plug#begin('~/.vim/plugged')

Plug 'nathanaelkane/vim-indent-guides'
Plug 'editorconfig/editorconfig-vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'https://gitlab.com/code-stats/code-stats-vim.git'

" Optional: If you want a nice status line in Vim
Plug 'vim-airline/vim-airline'

call plug#end()


" REQUIRED: set your API key
let g:codestats_api_key = 'SFMyNTY.Y205a1kyOXlaR1ZwY204PSMjTWpNeE9UYz0.4SyHx-951NDmH0188M85-Lbds79G83rJdU8NlJFTBQI'


" Optional: configure vim-airline to display status
let g:airline_section_x = airline#section#create_right(['tagbar', 'filetype', '%{CodeStatsXp()}'])
