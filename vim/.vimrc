" ==============================================================================
" Vanilla Server Vimrc
"
" Features:
"   - Zero external dependencies.
"   - Auto-detects indentation (spaces vs tabs) on file load.
"   - Native file explorer (Netrw).
"   - Remote clipboard support via OSC52.
"   - Buffer management (Tab/S-Tab).
"
" Keybindings:
"   <Leader>   : Space
"   <Leader>w  : Save file
"   <Leader>q  : Quit
"   <Leader>x  : Save and quit
"   <Leader>d  : Close (delete) current buffer
"   <Leader>l  : List all open buffers
"   <Leader>b  : Toggle file explorer (Netrw)
"   <Leader>h  : Clear search highlighting
"   <Leader>r  : Toggle line numbers (3-state: Off, Absolute, Relative)
"   <Leader>m  : Toggle mouse mode
"   <Leader>c  : Copy visual selection to local clipboard (OSC52 over SSH/TMUX)
"   <Leader>y  : (like leader+c)
"   <Leader>p/P: Paste from system clipboard
"   <Leader>s  : Replace word under cursor (Normal) / Replace selection (Visual)
"   <Tab>      : Next buffer
"   <S-Tab>    : Previous buffer
"   <C-h/j/k/l>: Navigate split windows
"   <M-Up/Down>: Move line(s) up or down (Alt+Up/Alt+Down)
" ==============================================================================

" General
set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set hidden
set history=1000

" UI
set t_Co=256
set termguicolors
set background=dark

" Graceful colorscheme fallback
try
    colorscheme one-monokai
catch
    colorscheme desert
endtry

set number
set relativenumber
set cursorline
set showcmd
set wildmenu
set lazyredraw
set showmatch
set scrolloff=8
set signcolumn=yes

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Mouse
set mouse=a

" Default Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent

" Auto-detect indentation from file content
function! DetectIndent()
    let l:has_tabs = 0
    let l:min_spaces = 100
    let l:space_lines = 0

    for l:i in range(1, min([line('$'), 100]))
        let l:line = getline(l:i)
        if l:line =~# '^\t'
            let l:has_tabs += 1
        elseif l:line =~# '^ \+'
            let l:space_lines += 1
            let l:spaces = len(matchstr(l:line, '^ \+'))
            if l:spaces < l:min_spaces && l:spaces > 0
                let l:min_spaces = l:spaces
            endif
        endif
    endfor

    if l:has_tabs > l:space_lines
        setlocal noexpandtab
        setlocal shiftwidth=4
        setlocal tabstop=4
    elseif l:space_lines > 0
        setlocal expandtab
        if l:min_spaces <= 8
            let &l:shiftwidth = l:min_spaces
            let &l:tabstop = l:min_spaces
        endif
    endif
endfunction

autocmd BufReadPost * call DetectIndent()

" Remove trailing whitespace on save
function! CleanWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfunction
autocmd BufWritePre * call CleanWhitespace()

" Language specific overrides for new files
autocmd FileType yaml,yml setlocal tabstop=2 shiftwidth=2 expandtab cursorcolumn
autocmd FileType go setlocal tabstop=4 shiftwidth=4 noexpandtab
autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
autocmd FileType sh,bash,zsh setlocal tabstop=2 shiftwidth=2 expandtab

" Netrw file explorer
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25

" Keybindings
let mapleader = " "

" Toggle mouse mode
nnoremap <leader>m :let &mouse = &mouse ==# 'a' ? '' : 'a'<CR>:echo "Mouse: " . (&mouse ==# 'a' ? "ON" : "OFF")<CR>

" Toggle line numbers (3-state)
function! ToggleLineNumbers()
    if &relativenumber
        set nonumber
        set norelativenumber
        echo "Line numbers: OFF"
    elseif &number
        set relativenumber
        echo "Line numbers: RELATIVE"
    else
        set number
        echo "Line numbers: ABSOLUTE"
    endif
endfunction
nnoremap <leader>r :call ToggleLineNumbers()<CR>

" Core OSC52 Copy Function (Sends text over SSH to Local OS)
function! SendOSC52(text)
    let l:b64 = system('base64 | tr -d "\n"', a:text)
    let l:osc = "\x1b]52;c;" . l:b64 . "\x07"
    if !empty($TMUX) || $TERM =~# '^screen' || $TERM =~# '^tmux'
        let l:osc = "\x1bPtmux;\x1b" . substitute(l:osc, "\x1b", "\x1b\x1b", 'g') . "\x1b\\"
    endif
    if exists('*echoraw')
        call echoraw(l:osc)
    elseif filewritable('/dev/tty')
        call writefile([l:osc], '/dev/tty', 'b')
    else
        call system("printf '%s' " . shellescape(l:osc) . " > /dev/tty")
    endif
endfunction

" CLIPBOARD A: INTERNAL (Remote Vim Only)
" Standard 'y', 'd', 'p', 'P' work normally.
" They stay inside Vim on the server. No network traffic.

" CLIPBOARD B: EXTERNAL (Local Physical Machine)
" Use <leader>y (or standard "+y) to copy explicitly to your physical computer
vnoremap <silent> <leader>y y:call SendOSC52(@")<CR>
nnoremap <silent> <leader>y yy:call SendOSC52(@")<CR>
vnoremap <silent> <leader>c y:call SendOSC52(@")<CR>
vnoremap <silent> "+y y:call SendOSC52(@")<CR>
nnoremap <silent> "+y yy:call SendOSC52(@")<CR>

" Automatically copy all yanks to the system clipboard via OSC52
if exists('##TextYankPost')
    augroup OSC52Yank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call SendOSC52(getreg(v:event.regname == "" ? '"' : v:event.regname)) | endif
    augroup END
endif

" Basic file ops
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Buffer navigation
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>d :bdelete<CR>
nnoremap <leader>l :ls<CR>:b<Space>

" Explorer & Search
nnoremap <leader>b :Lexplore<CR>
nnoremap <leader>h :nohlsearch<CR>

" Find and replace
nnoremap <leader>s :%s/<C-r><C-w>//g<Left><Left>
vnoremap <leader>s "hy:%s/<C-r>=escape(@h, '/')<CR>//g<Left><Left>

" Move lines up and down (Alt+Up / Alt+Down)
nnoremap <M-Down> :m .+1<CR>==
nnoremap <M-Up> :m .-2<CR>==
inoremap <M-Down> <Esc>:m .+1<CR>==gi
inoremap <M-Up> <Esc>:m .-2<CR>==gi
vnoremap <M-Down> :m '>+1<CR>gv=gv
vnoremap <M-Up> :m '<-2<CR>gv=gv

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
