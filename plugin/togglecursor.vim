vim9script
# ============================================================================
# File:         togglecursor.vim
# Description:  Toggles cursor shape in the terminal
# Maintainer:   John Szakmeister <john@szakmeister.net>
# Version:      0.6.0
# License:      Same license as Vim.
# ============================================================================

if exists('g:loaded_togglecursor') || &cp || !has("cursorshape")
  finish
endif

# Bail out early if not running under a terminal.
if has('gui_running')
    finish
endif

if !exists('g:togglecursor_disable_default_init')
    g:togglecursor_disable_default_init = 0
endif

g:loaded_togglecursor = 1

var S_cursorshape_underline = "\<Esc>]50;CursorShape=2;BlinkingCursorEnabled=0\x7"
var S_cursorshape_line = "\<Esc>]50;CursorShape=1;BlinkingCursorEnabled=0\x7"
var S_cursorshape_block = "\<Esc>]50;CursorShape=0;BlinkingCursorEnabled=0\x7"

var S_cursorshape_blinking_underline = "\<Esc>]50;CursorShape=2;BlinkingCursorEnabled=1\x7"
var S_cursorshape_blinking_line = "\<Esc>]50;CursorShape=1;BlinkingCursorEnabled=1\x7"
var S_cursorshape_blinking_block = "\<Esc>]50;CursorShape=0;BlinkingCursorEnabled=1\x7"

# Note: newer iTerm's support the DECSCUSR extension (same one used in xterm).

var S_xterm_underline = "\<Esc>[4 q"
var S_xterm_line = "\<Esc>[6 q"
var S_xterm_block = "\<Esc>[2 q"

# Not used yet, but don't want to forget them.
var S_xterm_blinking_block = "\<Esc>[0 q"
var S_xterm_blinking_line = "\<Esc>[5 q"
var S_xterm_blinking_underline = "\<Esc>[3 q"

# Detect whether this version of vim supports changing the replace cursor
# natively.
var S_sr_supported = exists('+t_SR')

var S_supported_terminal = ''

# Check for supported terminals.
if exists('g:togglecursor_force') && g:togglecursor_force != ''
    if count(['xterm', 'cursorshape'], g:togglecursor_force) == 0
        echoerr 'Invalid value for g:togglecursor_force: ' ..
                \ g:togglecursor_force
    else
        S_supported_terminal = g:togglecursor_force
    endif
endif

function! S_GetXtermVersion(version)
    return str2nr(matchstr(a:version, '\v^XTerm\(\zs\d+\ze\)'))
endfunction

if S_supported_terminal == ''
    # iTerm, xterm, and VTE based terminals support DECSCUSR.
    if $TERM_PROGRAM == 'iTerm.app' || exists('$ITERM_SESSION_ID')
        var S_supported_terminal = 'xterm'
    elseif $TERM_PROGRAM == 'Apple_Terminal' && str2nr($TERM_PROGRAM_VERSION) >= 388
        var S_supported_terminal = 'xterm'
    elseif $TERM == 'xterm-kitty'
        var S_supported_terminal = 'xterm'
    elseif $TERM == 'rxvt-unicode' || $TERM == 'rxvt-unicode-256color'
        var S_supported_terminal = 'xterm'
    elseif str2nr($VTE_VERSION) >= 3900
        var S_supported_terminal = 'xterm'
    elseif S_GetXtermVersion($XTERM_VERSION) >= 252
        var S_supported_terminal = 'xterm'
    elseif $TERM_PROGRAM == 'Konsole' || exists('$KONSOLE_DBUS_SESSION')
        # This detection is not perfect.  KONSOLE_DBUS_SESSION seems to show
        # up in the environment despite running under tmux in an ssh
        # session if you have also started a tmux session locally on target
        # box under KDE.

        var S_supported_terminal = 'cursorshape'
    endif
endif

if S_supported_terminal == ''
    # The terminal is not supported, so bail.
    finish
endif


# -------------------------------------------------------------
# Options
# -------------------------------------------------------------

if !exists('g:togglecursor_default')
    g:togglecursor_default = 'blinking_block'
endif

if !exists('g:togglecursor_insert')
    g:togglecursor_insert = 'blinking_line'
    if $XTERM_VERSION != '' && S_GetXtermVersion($XTERM_VERSION) < 282
        g:togglecursor_insert = 'blinking_underline'
    endif
endif

if !exists('g:togglecursor_replace')
    g:togglecursor_replace = 'blinking_underline'
endif

if !exists('g:togglecursor_leave')
    if str2nr($VTE_VERSION) >= 3900
        g:togglecursor_leave = 'blinking_block'
    else
        g:togglecursor_leave = 'block'
    endif
endif

if !exists('g:togglecursor_enable_tmux_escaping')
    g:togglecursor_enable_tmux_escaping = 0
endif

if g:togglecursor_enable_tmux_escaping
    var S_in_tmux = exists('$TMUX')
else
    var S_in_tmux = 0
endif


# -------------------------------------------------------------
# Functions
# -------------------------------------------------------------

function! S_TmuxEscape(line)
    # Tmux has an escape hatch for talking to the real terminal.  Use it.
    let escaped_line = substitute(a:line, "\<Esc>", "\<Esc>\<Esc>", 'g')
    return "\<Esc>Ptmux;" .. escaped_line .. "\<Esc>\\"
endfunction

function! S_SupportedTerminal()
    if S_supported_terminal == ''
        return 0
    endif

    return 1
endfunction

function! S_GetEscapeCode(shape)
    if !S_SupportedTerminal()
        return ''
    endif

    let l:escape_code = S_{S_supported_terminal}_{a:shape}

    if S_in_tmux
        return S_TmuxEscape(l:escape_code)
    endif

    return l:escape_code
endfunction

function! S_ToggleCursorInit()
    if !S_SupportedTerminal()
        return
    endif

    let &t_EI = S_GetEscapeCode(g:togglecursor_default)
    let &t_SI = S_GetEscapeCode(g:togglecursor_insert)
    if S_sr_supported
        let &t_SR = S_GetEscapeCode(g:togglecursor_replace)
    endif
endfunction

function! S_ToggleCursorLeave()
    # One of the last codes emitted to the terminal before exiting is the "out
    # of termcap" sequence.  Tack our escape sequence to change the cursor type
    # onto the beginning of the sequence.
    let &t_te = S_GetEscapeCode(g:togglecursor_leave) .. &t_te
endfunction

function! S_ToggleCursorByMode()
    if v:insertmode == 'r' || v:insertmode == 'v'
        let &t_SI = S_GetEscapeCode(g:togglecursor_replace)
    else
        # Default to the insert mode cursor.
        let &t_SI = S_GetEscapeCode(g:togglecursor_insert)
    endif
endfunction

# Setting t_ti allows us to get the cursor correct for normal mode when we first
# enter Vim.  Having our escape come first seems to work better with tmux and
# Konsole under Linux.  Allow users to turn this off, since some users of VTE
# 0.40.2-based terminals seem to have issues with the cursor disappearing in the
# certain environments.
if g:togglecursor_disable_default_init == 0
    let &t_ti = S_GetEscapeCode(g:togglecursor_default) .. &t_ti
endif

augroup ToggleCursorStartup
    autocmd!
    autocmd VimEnter * call <SID>ToggleCursorInit()
    autocmd VimLeave * call <SID>ToggleCursorLeave()
    if !S_sr_supported
        autocmd InsertEnter * call <SID>ToggleCursorByMode()
    endif
augroup END
