# Key bindings

# Use vim mode
bindkey -v

# Reduce delay when switching to normal mode (default is 0.4s)
KEYTIMEOUT=1

# Cursor shape changes for different vim modes
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      echo -ne '\e[1 q';; # block cursor in normal mode
    viins|main) echo -ne '\e[5 q';; # beam cursor in insert mode
  esac
}
zle -N zle-keymap-select

function zle-line-init {
  echo -ne '\e[5 q' # beam cursor on init
}
zle -N zle-line-init

# Reset cursor on preexec
preexec() { echo -ne '\e[5 q' ;}

# Keep useful emacs keybindings in insert mode
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
# bindkey -M viins '^R' history-incremental-search-backward  # Commented out to allow FZF's Ctrl+R binding

# Fix backspace and delete in vim mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# Edit command line in $EDITOR with 'v' in normal mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Undo and redo in normal mode
bindkey -M vicmd 'u' undo
bindkey -M vicmd '^R' redo

# History substring search (up/down arrows and vim keys)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

# Vim mode - use j/k for history substring search in normal mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Delete key
bindkey '^[[3~' delete-char

# Line editing
bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^[d' kill-word

# History search
# bindkey '^R' history-incremental-search-backward
# bindkey '^S' history-incremental-search-forward

# Completion
bindkey '^[[Z' reverse-menu-complete

# Custom key bindings - add to ~/.config/zsh/local.zsh
