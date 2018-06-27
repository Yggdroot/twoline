" ============================================================================
" File:        twoline.vim
" Description:
" Author:      Yggdroot <archofortune@gmail.com>
" Website:     https://github.com/Yggdroot
" Note:
" License:     Apache License, Version 2.0
" ============================================================================

if exists('g:twoline_loaded') || &compatible
    finish
else
    let g:twoline_loaded = 1
endif

if v:version < 704
    finish
endif

let s:tl_vim_enter = 0

function! s:UpdateTabline(change_event)
    if s:tl_vim_enter == 0
        return
    endif
    call twoline#UpdateTabline(a:change_event)
endfunction

function! s:VimEnter()
    let s:tl_vim_enter = 1
    if bufnr('$') < 2
        return
    endif
    call s:UpdateTabline(0)
endfunction

function! s:BufferDeleted(buffer_number)
    call twoline#BufferDeleted(a:buffer_number)
endfunction

function! s:SwitchToNext()
    call twoline#SwitchToNext()
endfunction

function! s:SwitchToPrevious()
    call twoline#SwitchToPrevious()
endfunction

function! s:DeleteCurrentBuffer()
    call twoline#DeleteCurrentBuffer()
endfunction

function! s:Close()
    call twoline#Close()
endfunction

function! s:DefineAutocmds()
    augroup twoline
        autocmd!
        autocmd VimEnter * call s:VimEnter()
        autocmd BufWinEnter * call s:UpdateTabline(0)
        autocmd CursorMoved,CursorMovedI,BufWritePost * call s:UpdateTabline(1)
        autocmd BufDelete,BufWipeout * call s:BufferDeleted(expand('<abuf>'))
    augroup END
endfunction

function! s:UndefineAutocmds()
    augroup twoline
        autocmd!
    augroup END
endfunction

call s:DefineAutocmds()

command! -bar TlBufferNext call s:SwitchToNext()
command! -bar TlBufferPrev call s:SwitchToPrevious()
command! -bar TlBufferDelete call s:DeleteCurrentBuffer()
command! -bar TlTablineClose call s:Close()
command! -bar TlTablineEnable call s:DefineAutocmds() | call s:UpdateTabline(0)
command! -bar TlTablineDisable TlTablineClose | call s:UndefineAutocmds()

nnoremap <silent> <Plug>TlBufferNext :echo<CR>:silent TlBufferNext<CR>
nnoremap <silent> <Plug>TlBufferPrev :echo<CR>:silent TlBufferPrev<CR>
nnoremap <silent> <Plug>TlBufferDelete :echo<CR>:silent TlBufferDelete<CR>
nnoremap <silent> <Plug>TlTablineClose :TlTablineClose<CR>
nnoremap <silent> <Plug>TlTablineEnable :TlTablineEnable<CR>
nnoremap <silent> <Plug>TlTablineDisable :TlTablineDisable<CR>

let s:TL_mode = {
            \ "n":  "Normal",
            \ "no": "Normal",
            \ "i":  "Insert",
            \ "ic": "Insert",
            \ "ix": "Insert",
            \ "v":  "Visual",
            \ "V":  "Visual-Line",
            \ "\<C-V>": "Visual-Block",
            \ "s":  "Select",
            \ "S":  "Select-Line",
            \ "\<C-S>": "Select-Block",
            \ "R":  "Replace",
            \ "Rc": "Replace",
            \ "Rv": "Replace",
            \ "Rx": "Replace",
            \ "t":  "Terminal",
            \}

function! g:TL_mode()
    return get(s:TL_mode, mode(), "Normal")
endfunction

let s:TL_stl_item  = {
            \ 'left': {
            \   0: "%{g:TL_mode()}%{&paste ? '  PASTE' : ''}",
            \   1: "%{&readonly ? '\U1f512' : ''}%<%F%m 『%{&ft!=''?&ft:'?'}』",
            \ },
            \ 'right':{
            \   0: "%3p%%/%L",
            \   1: "%7(%l,%v%)",
            \   2: "『%{&ff}』『%{&fenc==''?&enc:&fenc}』"
            \ }
            \}

function! s:InitVar(var, value)
    if !exists(a:var)
        exec 'let '.a:var.'='.string(a:value)
    endif
endfunction

call s:InitVar('g:TL_stl_item', s:TL_stl_item)
call s:InitVar('g:TL_stl_origin_mode', "")

function! s:InitColor()
    hi! def TL_stl_blank       gui=NONE guifg=#9e9e9e guibg=#363636 cterm=NONE ctermfg=247 ctermbg=236
    hi! def TL_stl_mode_normal gui=bold guifg=#005f00 guibg=#afdf00 cterm=bold ctermfg=22 ctermbg=148
    hi! def TL_stl_mode_insert gui=bold guifg=#044d22 guibg=#a7c18b cterm=bold ctermfg=22 ctermbg=150
    hi! def TL_stl_mode_visual gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_visual_line gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_visual_block gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_select gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_select_line gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_select_block gui=bold guifg=#870000 guibg=#ff8700 cterm=bold ctermfg=88 ctermbg=208
    hi! def TL_stl_mode_replace gui=bold guifg=#000000 guibg=#f28379 cterm=bold ctermfg=16 ctermbg=210
    hi! def TL_stl_mode_terminal gui=bold guifg=#005f00 guibg=#afdf00 cterm=bold ctermfg=22 ctermbg=148

    hi! def link TL_stl_left_0 TL_stl_mode_normal
    hi! def TL_stl_left_1      gui=NONE guifg=#87ceeb guibg=#4d4d4d cterm=NONE ctermfg=117 ctermbg=239
    hi! def TL_stl_left_2      gui=NONE guifg=#9e9e9e guibg=#363636 cterm=NONE ctermfg=247 ctermbg=236
    hi! def TL_stl_left_3      gui=NONE guifg=#87ceeb guibg=#4d4d4d cterm=NONE ctermfg=117 ctermbg=239
    hi! def TL_stl_left_4      gui=NONE guifg=#87ceeb guibg=#4d4d4d cterm=NONE ctermfg=117 ctermbg=239
    hi! def link TL_stl_left_5 TL_stl_blank

    hi! def TL_stl_right_0     gui=NONE guifg=#404040 guibg=#d0d0d0 cterm=NONE ctermfg=241 ctermbg=252
    hi! def TL_stl_right_1     gui=NONE guifg=#e8e8e8 guibg=#646464 cterm=NONE ctermfg=253 ctermbg=241
    hi! def TL_stl_right_2     gui=NONE guifg=#afafaf guibg=#484848 cterm=NONE ctermfg=248 ctermbg=238
    hi! def TL_stl_right_3     gui=NONE guifg=#9e9e9e guibg=#363636 cterm=NONE ctermfg=247 ctermbg=236
    hi! def TL_stl_right_4     gui=NONE guifg=#9e9e9e guibg=#363636 cterm=NONE ctermfg=247 ctermbg=236
    hi! def link TL_stl_right_5 TL_stl_blank

    if !has_key(g:TL_stl_seperator, "font")
        let g:TL_stl_seperator["font"] = ""
    endif

    for i in range(5)
        let synId_left_0 = synIDtrans(hlID(printf("TL_stl_left_%d", i)))
        let synId_left_1 = synIDtrans(hlID(printf("TL_stl_left_%d", i+1)))
        let synId_right_0 = synIDtrans(hlID(printf("TL_stl_right_%d", i)))
        let synId_right_1 = synIDtrans(hlID(printf("TL_stl_right_%d", i+1)))
        exec printf("hi! def TL_stl_sep_left_%d gui=NONE guifg=%s guibg=%s cterm=NONE ctermfg=%s ctermbg=%s font=%s",
                    \ i, synIDattr(synId_left_0, "bg", "gui"), synIDattr(synId_left_1, "bg", "gui"),
                    \ synIDattr(synId_left_0, "bg", "cterm"), synIDattr(synId_left_1, "bg", "cterm"),
                    \ g:TL_stl_seperator.font != "" ? "'" . g:TL_stl_seperator.font . "'" : "NONE")
        exec printf("hi! def TL_stl_sep_right_%d gui=NONE guifg=%s guibg=%s cterm=NONE ctermfg=%s ctermbg=%s font=%s",
                    \ i, synIDattr(synId_right_0, "bg", "gui"), synIDattr(synId_right_1, "bg", "gui"),
                    \ synIDattr(synId_right_0, "bg", "cterm"), synIDattr(synId_right_1, "bg", "cterm"),
                    \ g:TL_stl_seperator.font != "" ? "'" . g:TL_stl_seperator.font . "'" : "NONE")
    endfor

    let mode = ["normal", "insert", "visual", "visual_line", "visual_block", "select", "select_line", "select_block", "replace", "terminal"]
    for m in mode
        let fg_synId = synIDtrans(hlID(printf("TL_stl_mode_%s", m)))
        let bg_synId = synIDtrans(hlID("TL_stl_left_1"))
        exec printf("hi! def TL_stl_sep_%s gui=NONE guifg=%s guibg=%s cterm=NONE ctermfg=%s ctermbg=%s font=%s",
                    \ m, synIDattr(fg_synId, "bg", "gui"), synIDattr(bg_synId, "bg", "gui"),
                    \ synIDattr(fg_synId, "bg", "cterm"), synIDattr(bg_synId, "bg", "cterm"),
                    \ g:TL_stl_seperator.font != "" ? "'" . g:TL_stl_seperator.font . "'" : "NONE")
    endfor
endfunction

function! g:TL_stl_left(n)
    if has_key(g:TL_stl_item, "left") && has_key(g:TL_stl_item.left, a:n)
        return g:TL_stl_item.left[a:n]
    else
        return ""
    endif
endfunction

function! g:TL_stl_right(n)
    if has_key(g:TL_stl_item, "right") && has_key(g:TL_stl_item.right, a:n)
        return g:TL_stl_item.right[a:n]
    else
        return ""
    endif
endfunction

function! g:TL_stl_link()
    if synIDattr(synIDtrans(hlID("TL_stl_left_0")), "fg", "gui") == ""
        call s:InitColor()
    endif
    let mode = g:TL_mode()
    if mode != g:TL_stl_origin_mode
        let g:TL_stl_origin_mode = mode

        let mode = tr(tolower(mode), "-", "_")
        exec printf("hi! link TL_stl_left_0 TL_stl_mode_%s", mode)
        exec printf("hi! link TL_stl_sep_left_0 TL_stl_sep_%s", mode)
    endif
    return ""
endfunction

function! g:TL_statusline()
    let sep_left = g:TL_stl_seperator.left
    let sep_right = g:TL_stl_seperator.right
    let stl  = "%{g:TL_stl_link()}"
    let stl .= g:TL_stl_left(0) == "" ? "" : "%#TL_stl_left_0# " . g:TL_stl_left(0) . " %#TL_stl_sep_left_0#" . sep_left
    let stl .= g:TL_stl_left(1) == "" ? "" : "%#TL_stl_left_1# " . g:TL_stl_left(1) . " %#TL_stl_sep_left_1#" . sep_left
    let stl .= g:TL_stl_left(2) == "" ? "" : "%#TL_stl_left_2# " . g:TL_stl_left(2) . " %#TL_stl_sep_left_2#" . sep_left
    let stl .= g:TL_stl_left(3) == "" ? "" : "%#TL_stl_left_3# " . g:TL_stl_left(3) . " %#TL_stl_sep_left_3#" . sep_left
    let stl .= g:TL_stl_left(4) == "" ? "" : "%#TL_stl_left_4# " . g:TL_stl_left(4) . " %#TL_stl_sep_left_4#" . sep_left
    let stl .= "%#TL_stl_blank#%="
    let stl .= g:TL_stl_right(4) == "" ? "" : "%#TL_stl_sep_right_4#" . sep_right . "%#TL_stl_right_4# " . g:TL_stl_right(4) . " "
    let stl .= g:TL_stl_right(3) == "" ? "" : "%#TL_stl_sep_right_3#" . sep_right . "%#TL_stl_right_3# " . g:TL_stl_right(3) . " "
    let stl .= g:TL_stl_right(2) == "" ? "" : "%#TL_stl_sep_right_2#" . sep_right . "%#TL_stl_right_2# " . g:TL_stl_right(2) . " "
    let stl .= g:TL_stl_right(1) == "" ? "" : "%#TL_stl_sep_right_1#" . sep_right . "%#TL_stl_right_1# " . g:TL_stl_right(1) . " "
    let stl .= g:TL_stl_right(0) == "" ? "" : "%#TL_stl_sep_right_0#" . sep_right . "%#TL_stl_right_0# " . g:TL_stl_right(0) . " "
    return stl
endfunction

set laststatus=2
let &statusline = g:TL_statusline()
