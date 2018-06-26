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

if has("python3")
    let s:py = "py3"
elseif has("python")
    let s:py = "py"
else
    finish
endif

if exists("g:tl_python_version")
    let s:py = "py".string(g:tl_python_version)
endif

function! s:InitVar(var, value)
    if !exists(a:var)
        exec 'let '.a:var.'='.string(a:value)
    endif
endfunction

call s:InitVar('g:TL_scroll_mode', 0)
call s:InitVar('g:TL_stl_seperator', {
            \ 'left': '►',
            \ 'right': '◄',
            \ 'font': ''
            \})

function! g:TL_tabline_init_color()
    if synIDattr(synIDtrans(hlID("TL_tabline_right")), "fg", "gui") == ""
        hi! def TL_tabline_right gui=NONE guifg=#ebebeb guibg=#707070 cterm=NONE ctermfg=255 ctermbg=242
        hi! def TL_tabline       gui=NONE guifg=#87ceeb guibg=#4d4d4d cterm=NONE ctermfg=117 ctermbg=239

        let fg_synId = synIDtrans(hlID("TL_tabline_right"))
        let bg_synId = synIDtrans(hlID("TL_tabline"))
        exec printf("hi! def TL_tabline_sep_right gui=NONE guifg=%s guibg=%s cterm=NONE ctermfg=%s ctermbg=%s font=%s",
                    \ synIDattr(fg_synId, "bg", "gui"), synIDattr(bg_synId, "bg", "gui"),
                    \ synIDattr(fg_synId, "bg", "cterm"), synIDattr(bg_synId, "bg", "cterm"),
                    \ g:TL_stl_seperator.font != "" ? "'" . g:TL_stl_seperator.font . "'" : "NONE")
    endif
    return ""
endfunction

let s:tl_vim_enter = 0

exec s:py "<< EOF"
import vim
import re
import os.path

class Twoline(object):
    def __init__(self):
        self._tabline_buf = None

        self._buf_dict = {}
        self._buf_list = []

    def _buffer_count(self):
        return len([b for b in vim.buffers if vim.eval("getbufvar(%d, '&buftype')" % b.number) == ""
                    and vim.eval("getbufvar(%d, '&buflisted')" % b.number) == "1"])

    def _buffer_window(self):
        for w in vim.windows:
            if self._tabline_buf == w.buffer:
                return w
        return None

    def _buffer_is_changed(self, buffer):
        if "buf_changed" not in buffer.vars:
            buffer.vars["buf_changed"] = False
        status = buffer.vars["buf_changed"]
        buffer.vars["buf_changed"] = buffer.options["modified"]

        return status != buffer.vars["buf_changed"]

    def _create_tabline(self):
        vim.command("silent topleft sp $VIM/__twoline__")
        vim.current.window.height = 1
        vim.current.window.cursor = (1, 0)

        vim.current.buffer.options["buflisted"] = False
        vim.current.buffer.options["buftype"] = "nofile"
        vim.current.buffer.options["bufhidden"] = "hide"
        vim.current.buffer.options["undolevels"] = -1
        vim.current.buffer.options["swapfile"] = False
        vim.command("setlocal filetype=twoline")

        vim.current.window.options["list"] = False
        vim.current.window.options["number"] = False
        vim.current.window.options["relativenumber"] = False
        vim.current.window.options["spell"] = False
        vim.current.window.options["wrap"] = False
        vim.current.window.options["foldenable"] = False
        vim.current.window.options["foldcolumn"] = 0
        vim.current.window.options["foldmethod"] = "manual"
        vim.current.window.options["winfixheight"] = True
        vim.current.window.options["winfixwidth"] = True
        vim.current.window.options["statusline"] = "%{{g:TL_tabline_init_color()}}%#TL_tabline#%=%#TL_tabline_sep_right#{0}%#TL_tabline_right# Total: %-3{{g:TL_total_buf_num}}".format(
                                                        vim.eval("g:TL_stl_seperator.right"))

        vim.command("augroup twoline_highlight")
        vim.command("autocmd! BufEnter,BufLeave,CursorMoved <buffer> 3match none")
        vim.command("autocmd! ColorScheme * doautoa syntax")
        vim.command("augroup END")
        vim.command("noremap <silent> <buffer> <LeftRelease> :call g:Twoline_EnterTabline()<cr><LeftRelease>")
        vim.command("noremap <silent> <buffer> <CR> :call g:Twoline_EnterTabline()<cr>")

        return vim.current.buffer

    def escQuote(self, str):
        return "" if str is None else str.replace("'","''")

    def _adjust(self, buffer):
        if buffer in self._buf_dict:
            orig_window = vim.current.window
            tabline_win = self._buffer_window()

            saved_eventignore = vim.options['eventignore']
            vim.options['eventignore'] = 'all'
            vim.current.window = tabline_win
            try:
                vim.command("norm! g0")
                lhs = int(vim.eval("virtcol('.')")) - 1
                vim.command("norm! g$")
                rhs = int(vim.eval("virtcol('.')"))
                match_obj = re.search("\[{}[: ].+?]\+?".format(self._buf_dict[buffer] + 1), self._tabline_buf[0])
                if match_obj:
                    left = int(vim.eval("strdisplaywidth('%s')" % self.escQuote(match_obj.string[:match_obj.start()])))
                    right = int(vim.eval("strdisplaywidth('%s')" % self.escQuote(match_obj.string[:match_obj.end()])))
                    if right > rhs:
                        if vim.eval("g:TL_scroll_mode") == "0":
                            vim.command("norm! {}zl".format((left + right - lhs - rhs)//2))
                        elif vim.eval("g:TL_scroll_mode") == "1":
                            vim.command("norm! {}zl".format(right - rhs))
                        else:
                            vim.command("norm! {}zl".format(left - lhs))
                    elif left < lhs:
                        if vim.eval("g:TL_scroll_mode") == "0":
                            vim.command("norm! {}zh".format((lhs + rhs - left - right)//2))
                        elif vim.eval("g:TL_scroll_mode") == "1":
                            vim.command("norm! {}zh".format(lhs - left))
                        else:
                            vim.command("norm! {}zh".format(rhs - right))

                    vim.command("norm! g0")
                    lhs = int(vim.eval("virtcol('.')")) - 1
                    rhs = lhs + vim.current.window.width
                    end = int(vim.eval("virtcol('$')"))
                    if end < rhs:
                        vim.command("norm! {}zh".format(rhs - end + 1))
            finally:
                vim.current.window = orig_window
                vim.options['eventignore'] = saved_eventignore

    def update_tabline(self, change_event):
        if vim.eval("s:tl_vim_enter") == '0':
            return

        if change_event:
            if not self._buffer_is_changed(vim.current.buffer):
                return

        orig_window = vim.current.window
        try:
            if self._tabline_buf is None:
                if self._buffer_count() > 1:
                    self._tabline_buf = self._create_tabline()
                    vim.current.window = orig_window
                else:
                    return
            else:
                tabline_win = self._buffer_window()
                if tabline_win: # tabline is already shown
                    if self._buffer_count() <= 1:
                        # Vim:E788: Not allowed to edit another buffer now
                        vim.command("silent! {}close!".format(tabline_win.number))
                        return
                else:   # tabline is hidden
                    if self._buffer_count() > 1:
                        self._create_tabline()
                    else:
                        return

            if self._tabline_buf:
                self._tabline_buf.options["modifiable"] = True

            self._tabline_buf[0] = ""
            self._buf_dict = {}
            self._buf_list = []
            for i, b in enumerate((b for b in vim.buffers if vim.eval("getbufvar(%d, '&buftype')" % b.number) == ""
                                    and vim.eval("getbufvar(%d, '&buflisted')" % b.number) == "1")):
                self._buf_list.append(b)
                self._buf_dict[b] = i
                self._tabline_buf[0] += "[{}{}{}]{}".format(i + 1, ':' if int(vim.eval("bufwinnr(%d)" % b.number)) > 1 else ' ',
                                                            re.sub("[][]", "", os.path.basename(b.name)) if b.name else "--No Name--",
                                                            '+' if b.options["modified"] else '')
            vim.command("let g:TL_total_buf_num = {}".format(len(self._buf_list)))
            self._adjust(orig_window.buffer)
        finally:
            if self._tabline_buf:
                self._tabline_buf.options["modifiable"] = False

    def switch_to(self, number):
        vim.current.buffer = self._buf_list[number - 1]

    def switch_to_next(self):
        if self._buffer_count() > 1:
            if self._buffer_window() and vim.current.buffer in self._buf_dict:
                vim.current.buffer = self._buf_list[(self._buf_dict[vim.current.buffer] + 1) % len(self._buf_list)]
            else:
                vim.command("bn")

    def switch_to_previous(self):
        if self._buffer_count() > 1:
            if self._buffer_window() and vim.current.buffer in self._buf_dict:
                vim.current.buffer = self._buf_list[self._buf_dict[vim.current.buffer] - 1]
            else:
                vim.command("bp")

    def enter_tabline(self):
        if vim.current.buffer != self._tabline_buf:
            return
        line = vim.current.buffer[0]
        _, cursor_col = vim.current.window.cursor
        left = line.rfind("[", 0, cursor_col+1)
        number = int(re.search("\d+", line[left+1:]).group(0))

        saved_eventignore = vim.options['eventignore']
        vim.options['eventignore'] = 'all'
        try:
            vim.command("wincmd p")
            if vim.current.buffer == self._tabline_buf:
                vim.command("wincmd w")
        finally:
            vim.options['eventignore'] = saved_eventignore
        self.switch_to(number)

    def _warning_dlg(self):
        if vim.current.buffer.options["modified"]:
            choice = vim.eval("confirm(expand('%') . ' has been modified!', '&Save\n&Discard\n&Cancel', 'Warning')")
            if choice == '1':
                vim.command("w!")
            elif choice == '2':
                return '!'
            else:
                return 'n'
        return ''

    def delete_current_buffer(self):
        choice = self._warning_dlg()
        if choice == 'n':
            return
        vim.current.buffer.options["bufhidden"] = "wipe"
        if self._buffer_count() > 1:
            if vim.current.buffer == self._buf_list[-1]:
                vim.command("buffer{} {}".format(choice, self._buf_list[self._buf_dict[vim.current.buffer] - 1].number))
            else:
                vim.command("buffer{} {}".format(choice, self._buf_list[self._buf_dict[vim.current.buffer] + 1].number))
        else:
            vim.command("bwipeout{}".format(choice))

    def buffer_deleted(self, number):
        tabline_win = self._buffer_window()
        if tabline_win:
            buf_count = len([b for b in vim.buffers if vim.eval("getbufvar(%d, '&buftype')" % b.number) == ""
                                and vim.eval("getbufvar(%d, '&buflisted')" % b.number) == "1" and b.number != number])
            if len(vim.windows) == 1:   # the only window is the tabline window
                saved_eventignore = vim.options['eventignore']
                vim.options['eventignore'] = 'all'
                try:
                    index = self._buf_dict[vim.buffers[number]]
                    if index == len(self._buf_list) - 1:
                        index -= 1
                    else:
                        index += 1

                    vim.command("buffer {}".format(self._buf_list[index].number))
                finally:
                    vim.options['eventignore'] = saved_eventignore

                if buf_count > 1:
                    self.update_tabline(0)

            elif buf_count < 2:
                vim.command("{}close!".format(tabline_win.number))

            self._tabline_buf.options["modifiable"] = True
            try:
                self._tabline_buf[0] = ""
                self._buf_list = [b for b in vim.buffers if vim.eval("getbufvar(%d, '&buftype')" % b.number) == ""
                                    and vim.eval("getbufvar(%d, '&buflisted')" % b.number) == "1" and b.number != number]
                self._buf_dict = {b:i for i,b in enumerate(self._buf_list)}
                for i, b in enumerate(self._buf_list):
                    self._tabline_buf[0] += "[{}{}{}]{}".format(i + 1, ':' if vim.eval("bufwinnr(%d)" % b.number) != '-1' else ' ',
                                                                re.sub("[][]", "", os.path.basename(b.name)) if b.name else "--No Name--",
                                                                '+' if b.options["modified"] else '')
                vim.command("let g:TL_total_buf_num = {}".format(len(self._buf_list)))
            finally:
                self._tabline_buf.options["modifiable"] = False

    def close(self):
        tabline_win = self._buffer_window()
        if tabline_win:
            vim.command("{}close!".format(tabline_win.number))


my_twoline = Twoline()

EOF

function! g:Twoline_EnterTabline()
exec s:py "<< EOF"
my_twoline.enter_tabline()
EOF
endfunction

function! s:UpdateTabline(change_event)
exec s:py "<< EOF"
my_twoline.update_tabline(int(vim.eval("a:change_event")))
EOF
endfunction

function! s:VimEnter()
    let s:tl_vim_enter = 1
    call s:UpdateTabline(0)
endfunction

function! s:BufferDeleted(buffer_number)
exec s:py "<< EOF"
my_twoline.buffer_deleted(int(vim.eval("a:buffer_number")))
EOF
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

command! -bar TlBufferNext exec s:py "my_twoline.switch_to_next()"
command! -bar TlBufferPrev exec s:py "my_twoline.switch_to_previous()"
command! -bar TlBufferDelete exec s:py "my_twoline.delete_current_buffer()"
command! -bar TlTablineClose exec s:py "my_twoline.close()"
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
