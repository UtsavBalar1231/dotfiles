# Shell aliases

# Modern tool replacements (only for installed tools)
command -v eza >/dev/null && alias ls='eza --icons --group-directories-first'
command -v eza >/dev/null && alias ll='eza -la --icons --group-directories-first'
command -v eza >/dev/null && alias la='eza -la --icons --group-directories-first'
command -v eza >/dev/null && alias tree='eza --tree --icons'

# Traditional tool improvements
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'

# History search
alias h='history'
alias hs='history | grep'

# Config editing shortcuts
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias zshconfig='${EDITOR:-nvim} ~/.config/zsh/.zshrc'
alias aliases='${EDITOR:-nvim} ~/.config/zsh/aliases.zsh'
alias reload='source ~/.zshrc'

# Network utilities
alias myip='curl -4 -s ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | grep -v "127.0.0.1"'
alias ports='netstat -tulanp'

# Quick server
alias serve='python3 -m http.server'

# Colorize grep
alias grep='grep --color=auto'

# Neovim shortcuts
alias nvim='nvim -p'
alias n='nvim'

# Archive the current directory into <name>.tar.gz in the parent directory.
# Extra args are forwarded to tar (e.g. `archivethisdir --exclude='*.log'`).
unalias archivethisdir 2>/dev/null   # idempotent re-source: drop stale alias from prior load
archivethisdir() {
  local name arg
  name=${PWD:t}        # zsh: tail of $PWD — basename without spawning a subshell
  if [[ $PWD == / ]]; then
    print -u2 "archivethisdir: refusing to archive /"
    return 1
  fi
  for arg in "$@"; do
    if [[ $arg != -* ]]; then
      print -u2 "archivethisdir: unexpected positional argument '$arg' — this command archives the current directory automatically."
      print -u2 "  Pass tar flags only (e.g. --exclude='*.log'). Drop '$arg' and rerun."
      return 2
    fi
  done
  tar -czvf "../${name}.tar.gz" -C .. "$@" "$name"
}

# Custom aliases - add to ~/.config/zsh/local.zsh for machine-specific ones
