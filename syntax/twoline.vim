" ============================================================================
" File:        twoline.vim
" Description: twoline syntax settings
" Author:      Yggdroot <archofortune@gmail.com>
" Website:     https://github.com/Yggdroot
" Note:
" License:     Apache License, Version 2.0
" ============================================================================

scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif

if has("syntax")
    syn clear
    syn match Tl_Number         '\[\zs\d* ' containedin=ALL
    syn match Tl_Normal         '\[\d* [^\]]*\]'
    syn match Tl_Changed        '\[\d* [^\]]*\]+'
    syn match Tl_VisualNumber   '\[\zs\d*:' containedin=ALL
    syn match Tl_VisibleNormal  '\[\d*:[^\]]*\]'
    syn match Tl_VisibleChanged '\[\d*:[^\]]*\]+'

    hi def Tl_Number guifg=#9dff42 guibg=NONE gui=NONE ctermfg=155 cterm=NONE
    hi def Tl_Normal guifg=#87ceeb guibg=NONE gui=NONE ctermfg=117 cterm=NONE
    hi def Tl_Changed guifg=#ff9a9a guibg=NONE gui=NONE ctermfg=210 cterm=NONE
    hi def Tl_VisualNumber guifg=#9dff42 guibg=#4d4d4d gui=bold ctermfg=155 ctermbg=239 cterm=bold
    hi def Tl_VisibleNormal guifg=#87ceeb guibg=#4d4d4d gui=bold ctermfg=117 ctermbg=239 cterm=bold
    hi def Tl_VisibleChanged guifg=#ff9a9a guibg=#4d4d4d gui=bold ctermfg=210 ctermbg=239 cterm=bold
endif

let b:current_syntax = "twoline"
