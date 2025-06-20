# Profiling
# zmodload zsh/zprof
# shellcheck disable=SC2034,SC2086,SC2296,SC2016,SC1090,SC1091,SC1094,SC2154

[[ -z "$XDG_CONFIG_HOME" ]] && export XDG_CONFIG_HOME=${HOME}/.config
[[ -z "$XDG_CACHE_HOME" ]] && export XDG_CACHE_HOME=${HOME}/.cache
[[ -z "$XDG_DATA_HOME" ]] && export XDG_DATA_HOME=${HOME}/.local/share
export TERM="xterm-256color"

# Enable history
export HISTSIZE=100000
export SAVEHIST=${HISTSIZE}
export HISTFILE=${HOME}/.zsh_history
export HIST_IGNORE="cd|ls|clear|clea|exit|history|n"
export HISTDUP=erase

setopt APPENDHISTORY
setopt SHAREHISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY

# Enable zsh command correction
setopt CORRECT

autoload -Uz compinit && compinit
zstyle :compinstall filename "$HOME/.zshrc"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# defer fzf-tab initialization until the first completion
zstyle ':fzf-tab:*' auto-insert false
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Enable aliases
setopt aliases

[[ -f ${XDG_CONFIG_HOME}/zsh/aliases.zsh ]] && source ${XDG_CONFIG_HOME}/zsh/aliases.zsh

# Key bindings
bindkey -v
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[F' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[3~' delete-word
bindkey '^[[2~' kill-line
bindkey '^[[3~' delete-char
bindkey -M viins "^E" end-of-line
bindkey -M viins "^A" beginning-of-line
bindkey -M viins "^P" history-search-backward
bindkey -M viins "^N" history-search-forward

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

### Added by Zinit's installer
if [[ ! -f ${XDG_DATA_HOME}/zinit/zinit.git/zinit.zsh ]]; then
	print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
	command mkdir -p "${XDG_DATA_HOME}/zinit" && command chmod g-rwX "${XDG_DATA_HOME}/zinit"
	command git clone https://github.com/zdharma-continuum/zinit "${XDG_DATA_HOME}/zinit/zinit.git" &&
		print -P "%F{33} %F{34}Installation successful.%f%b" ||
		print -P "%F{160} The clone has failed.%f%b"
fi

source "${XDG_DATA_HOME}/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
	zdharma-continuum/zinit-annex-as-monitor \
	zdharma-continuum/zinit-annex-bin-gem-node \
	zdharma-continuum/zinit-annex-patch-dl \
	zdharma-continuum/zinit-annex-rust

zinit light z-shell/F-Sy-H
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab

# zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240,bold,underline"

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# Cargo environment
if [ -f ${HOME}/.cargo/env ]; then
	source ${HOME}/.cargo/env
else
	[[ -d ${HOME}/.cargo/bin ]] && export PATH="${HOME}/.cargo/bin:${PATH}"
fi

# Rust
! command -v rustc >/dev/null 2>&1 && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable

# Python binaries
[[ -d ${HOME}/.local/bin ]] && export PATH="${HOME}/.local/bin":${PATH}

# Mason binaries
[[ -d ${XDG_DATA_HOME}/nvim/mason/bin ]] && export PATH="${XDG_DATA_HOME}/nvim/mason/bin":${PATH}

# Gitlint
[[ -f ${HOME}/.gitlint ]] && export GITLINT_CONFIG=${HOME}/.gitlint

# Edit command line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
fpath+=${ZDOTDIR:-${HOME}}/.zsh_functions

# Set default editor
command -v nvim >/dev/null 2>&1 && export EDITOR=nvim

# FZF
if [ ! -f ${HOME}/.fzf.zsh ]; then
	clone_repo_with_progress "https://github.com/junegunn/fzf" ${HOME}/.fzf
	${HOME}/.fzf/install
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun completions
[[ -s "${HOME}/.bun/_bun" ]] && source "${HOME}/.bun/_bun"

# bun
[[ -d $HOME/.bun ]] && export BUN_INSTALL="$HOME/.bun" && export PATH="$BUN_INSTALL/bin:$PATH"

# Local binaries
[[ -d $HOME/.local/bin ]] && export PATH=$HOME/.local/bin:$PATH

# Pyenv
if [ -d ${HOME}/.pyenv ]; then
	export PYENV_ROOT="$HOME/.pyenv"
	[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"
fi

# Set QT theme
command -v qt6ct >/dev/null && export QT_QPA_PLATFORMTHEME="qt6ct"

# Pywal
# if command -v wal >/dev/null; then
# 	(cat ${HOME}/.cache/wal/sequences &)
# fi

# Set newt colors
[[ -f $HOME/.newt-colors ]] && export NEWT_COLORS_FILE=${HOME}/.newt-colors

# Enable console cursor
function cursor_tty() {
	sudo su -c "setterm -cursor on >> /etc/issue"
}

# Theme
! command -v starship >/dev/null 2>&1 && curl -sS https://starship.rs/install.sh | sh

export STARSHIP_CONFIG=${XDG_CONFIG_HOME}/starship.toml
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi

eval "$(starship init zsh)"

get_latest_wallpaper() {
    local log_file="${XDG_CACHE_HOME}/wallpaper_changer.log"
    local regex="(Set wallpaper:|Animating GIF:) .+" 

    [[ ! -f "$log_file" ]] && echo "No log file found" && return 1

    # Extract last matching entry from log
    local wallpaper
    wallpaper=$(tac "$log_file" | awk -F'] ' '
        $2 ~ /Set wallpaper:|Animating GIF:/ { 
            sub(/ \(PID.*/, "", $2)  # Remove PID and any trailing garbage
            split($2, parts, /: /)
            print parts[2]
            exit
        }
    ')

    if [[ -n "$wallpaper" ]]; then
        echo "$wallpaper"
    else
        echo "No wallpaper found in logs"
        return 1
    fi
}

function debinstall() {
	ar x $1 data.tar.xz
	sudo mkdir /tmp/$1_dir
	sudo tar -C /tmp/$1_dir -xf data.tar.xz
	sudo rsync /tmp/$1_dir /
	rm -f data.tar.xz
	sudo rm -rf /tmp/$1_dir
}

export DOCKER_HOST=unix:///var/run/docker.sock

function 0x0() {
	local file_name="${1##*/}"
	if [ -z "$file_name" ]; then
		echo "Usage: 0x0 <file>"
		return 1
	fi

	curl -F "file=@$1" https://0x0.st
}

[[ "$TERM_PROGRAM" == "vscode" ]] && unset ARGV0

# zprof
