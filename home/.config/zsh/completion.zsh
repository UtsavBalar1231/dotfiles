# Completion system configuration

# Eagerly load completion modules at startup instead of relying on lazy
# module autoload. If zsh is upgraded by pacman while this shell is running,
# /usr/lib/zsh/$OLD_VERSION/ disappears and lazy autoload of zsh/computil
# fails with "command not found: comptry/comptags" on the first Tab press.
# Preloading makes running shells immune to package upgrades.
zmodload zsh/complete zsh/computil zsh/complist zsh/zutil 2>/dev/null

# Basic completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
[[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] && mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Kill command completion with process coloring
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# cd completion - ignore parent directory
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Ignore system users in completion
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm bin daemon mail ftp http nobody 'systemd-*' polkitd '_*'

# Sort files by modification time
zstyle ':completion:*' file-sort modification

# Vim-style navigation in completion menu
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# FZF-tab configuration
if command -v fzf &>/dev/null; then
  # Disable default menu (fzf-tab replaces it)
  zstyle ':completion:*' menu no

  # Preview configuration based on available tools
  if command -v eza &>/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
  fi

  if command -v bat &>/dev/null; then
    zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --line-range=:500 $realpath 2>/dev/null || eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 --color=always $realpath'
  fi

  # Better flags with tiebreak for improved sorting
  zstyle ':fzf-tab:*' fzf-flags --height=70% --preview-window=right:50%:wrap --tiebreak=chunk --ignore-case
  zstyle ':fzf-tab:*' switch-group ',' '.'

  # Use tmux popup if available
  [[ -n "$TMUX" ]] && zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

  # Git-specific previews
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
    'git diff $word | delta 2>/dev/null || git diff $word'
  zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
    'git log --color=always $word'
  zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
    'case "$group" in
      "modified file") git diff $word | delta 2>/dev/null || git diff $word ;;
      "recent commit object name") git log --oneline --color=always $word ;;
      *) eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 --color=always $realpath ;;
    esac'
fi