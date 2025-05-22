"......ARQUIVO
" Sai fora na marra!
imap <F12> <esc>:wqa!<cr>
 map <F12> :wqa!<cr>

set nu
set aw
syntax on

filetype plugin indent on
set enc=utf-8

call plug#begin('~/.vim/plugged')

	Plug 'nathanaelkane/vim-indent-guides'
	Plug 'editorconfig/editorconfig-vim'
	Plug 'ekalinin/Dockerfile.vim'
	Plug 'https://gitlab.com/code-stats/code-stats-vim.git'
	Plug 'dense-analysis/ale'

	" Optional: If you want a nice status line in Vim
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'

call plug#end()


" REQUIRED: set your API key
let g:codestats_api_key = 'REPLACE_THIS'


" Prettier
let g:ale_fixers = {
\	'javascript': ['prettier'],
\	'css': ['prettier'],
\	'html': ['prettier'],'*':['trim_whitespace']
\}
let g:ale_fix_on_save = 1


" Optional: configure vim-airline to display status
let g:airline#extensions#ale#enabled = 1
let g:airline_section_x = airline#section#create_right(['tagbar', 'filetype', '%{CodeStatsXp()}'])
let g:airline_powerline_fonts = 1
let g:airline_theme='deus'
let g:airline_solarized_enable_command_color = 1
