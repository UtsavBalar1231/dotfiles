
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash"

#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
. "$HOME/.cargo/env"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
# test modification
test line

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash"
export PATH="$HOME/.npm-global/bin:$PATH"

# mosh+tmux to kevinpi (scrollable, persistent)
kevin() { mosh distiller@100.89.61.95 -- tmux new-session -A -s "${1:-main}"; }  # kevin [name] = resilient named session

# native kitty ssh to kevinpi (instant local scrollback + copy-paste; no mosh resilience)
alias kevin-ssh="kitten ssh distiller@100.89.61.95"
