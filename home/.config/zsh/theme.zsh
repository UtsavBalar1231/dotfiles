# Prompt theme configuration

# Starship prompt (install: curl -sS https://starship.rs/install.sh | sh)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  echo "Starship not installed. Using fallback prompt."
  PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
fi