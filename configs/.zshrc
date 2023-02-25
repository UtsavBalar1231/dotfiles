# Enable history
setopt histignorespace
setopt histignoredups
setopt sharehistory
setopt incappendhistory

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Enable auto completion
setopt auto_menu
setopt auto_list
setopt auto_param_keys
setopt auto_param_slash
setopt auto_remove_slash

# Enable auto cd
setopt auto_cd

# Enable auto pushd
setopt auto_pushd

zstyle :compinstall filename '~/.zshrc'
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Enable aliases
setopt aliases
source ~/.config/zsh/aliases.zsh

# Enable syntax highlighting
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Enable auto suggestions
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Enable FZF
source ~/.config/zsh/plugins/fzf-git.sh/fzf-git.sh
source ~/.config/zsh/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

# Enable zsh f-sy-h
source ~/.config/zsh/plugins/F-Sy-H/F-Sy-H.plugin.zsh

# key bindings
bindkey -v

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[F' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[3~' delete-word
bindkey '^[[2~' kill-line
bindkey '^[[3~' delete-char

# Theme
source ~/.config/zsh/theme/cunt-theme.zsh-theme