togglecursor for Vim9
=====================

This plugin aims to provide the ability to change the cursor when entering Vim's
insert mode on terminals that support it.  Currently, that's limited to iTerm,
Konsole, and xterm is partially supported (creates an underline cursor instead
of line, by default).


Installation
------------

Unzip into ``~/.vim`` (or ``%USERPROFILE%\vimfiles`` on Windows).  You may also
install it under pathogen by extracting it into it's own directory under
``bundle``, such as ``~/.vim/bundle/vim-togglecursor``.

Vim also has a builtin plugin manager: simply clone (or symlink) the repository
under ``~/.vim/pack/<collection-name>/opt`` and load with
``packadd vim-togglecursor``.

This repository is a fork adapted for Vim 9+ / ``vim9script`` (which supports
script compilation and should thus be much lighter on CPU usage). Note that the
Vim9 version is on the ``vim9`` branch (the default for this repository).

The Vimscript version is on the ``master`` branch and was forked from::

    https://github.com/jszakmeister/vim-togglecursor


Terminal Support
----------------

Togglecursor supports a number of terminals at this point: Konsole, xterm,
kitty, iTerm, and pretty much anything that uses VTE under the hood.  If your
favorite terminal is not supported, it's pretty easy to do without modifying
Togglecursor.  The general outline is::

    " Do whatever is needed to detect your terminal.  Many times, this is
    " a simple check of the $TERM or $TERM_PROGRAM environment variables.
    if $TERM == 'my-terminal'
        " Set the kind of escape sequences to use.  Most use xterm-style
        " escaping, there are a few that use the iterm (CursorShape) style
        " sequences.  The two acceptable values to use here are: 'xterm'
        " and 'iterm'.
        let g:togglecursor_force = 'xterm'
    endif

Do this detection before the plugin is activated.  Togglecursor will see the
variable on load and proceed to use that style of escape sequences to change the
cursor.  This also works well if you happen to be running on a system that
doesn't have your favorite shell available since it will fallback to
Togglecursor's internal detection algorithm.

Note: looking for "xterm" in `$TERM` is not a good approach.  Many terminals
will set `TERM` to `xterm` or `xterm-256color`, but don't support the escape
sequences to change the cursor.  It's better to look for something unique to the
terminal application in the environment.
