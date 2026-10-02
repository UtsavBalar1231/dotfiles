# Bootstrap modular zsh configuration from ~/.config/zsh/
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc"


# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.config/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.config/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]
#compdef opencode
###-begin-opencode-completions-###
#
# yargs command completion script
#
# Installation: opencode completion >> ~/.zshrc
#    or opencode completion >> ~/.zprofile on OSX.
#
_opencode_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
  IFS=$si
  if [[ ${#reply} -gt 0 ]]; then
    _describe 'values' reply
  else
    _default
  fi
}
if [[ "'${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
  _opencode_yargs_completions "$@"
else
  compdef _opencode_yargs_completions opencode
fi
###-end-opencode-completions-###

export PATH="$HOME/.npm-global/bin:$PATH"

# OpenClaw Completion
[[ -r "$HOME/.openclaw/completions/openclaw.zsh" ]] && source "$HOME/.openclaw/completions/openclaw.zsh"

PATH="$HOME/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT;

# >>> Codex installer >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Codex installer <<<

# # Alacritty: auto-install the `alacritty` terminfo on remote hosts over ssh.
# # Wraps `ssh` for interactive use only — scp/git/rsync use the real binary.
# # Prefers the packaged /usr/bin/alacritty-ssh, falls back to the source tree.
# if [[ -x /usr/bin/alacritty-ssh ]]; then
#   ssh() { command alacritty-ssh "$@"; }
# elif [[ -x /home/utsav/dev/softs/alacritty/extra/alacritty-ssh ]]; then
#   ssh() { command /home/utsav/dev/softs/alacritty/extra/alacritty-ssh "$@"; }
# fi

# mosh+tmux to kevinpi (scrollable, persistent)
kevin() { mosh distiller@100.89.61.95 -- tmux new-session -A -s "${1:-main}"; }  # kevin [name] = resilient named session

# native kitty ssh to kevinpi (instant local scrollback + copy-paste; no mosh resilience)
alias kevin-ssh="kitten ssh distiller@100.89.61.95"
