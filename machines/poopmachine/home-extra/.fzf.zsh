# Setup fzf
# ---------
if [[ ! "$PATH" == */home/utsav/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/utsav/.fzf/bin"
fi

source <(fzf --zsh)
