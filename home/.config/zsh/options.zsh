# Shell options and behavior configuration

# History configuration
HISTSIZE=99999
SAVEHIST=99999
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
[[ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}/zsh" ]] && mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# History behavior - share across sessions, ignore duplicates, save timestamps
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE
setopt EXTENDED_HISTORY

# Directory navigation - auto cd, use directory stack
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME

# Completion behavior
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt PATH_DIRS
setopt AUTO_MENU
setopt AUTO_LIST
setopt NO_MENU_COMPLETE
setopt LIST_PACKED

# Globbing - extended syntax, case insensitive, include dotfiles
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
setopt NO_NOMATCH  # Pass literal string to command if glob fails (fixes git HEAD^ issue)

# Input/output
setopt INTERACTIVE_COMMENTS
setopt CORRECT
setopt NO_CORRECT_ALL
setopt MULTIOS
setopt NO_FLOW_CONTROL

# Job control
setopt NOTIFY
setopt LONG_LIST_JOBS
setopt NO_HUP
setopt NO_CHECK_JOBS

# Misc
setopt NO_BEEP
setopt PROMPT_SUBST
setopt TRANSIENT_RPROMPT
