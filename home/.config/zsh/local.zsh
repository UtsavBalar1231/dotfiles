# Local Aliases
alias :wq='sudo shutdown now'
# Git (conflicting with OMZ plugin)
alias gs='git status'
alias gl='git log'
alias gl1='git log --oneline'
alias gll='git log --oneline --graph --all --decorate'

# zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Yazi wrapper: quit with q to cd into Yazi's final directory, Q to keep cwd.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

# zi plugin manager (zoxide overwrites 'zi' with interactive directory picker)
alias zsh_zi='source ~/.zi/bin/zi.zsh && zi'

# starship
! command -v starship >/dev/null 2>&1 && curl -sS https://starship.rs/install.sh | sh
export STARSHIP_CONFIG=${XDG_CONFIG_HOME}/starship.toml
eval "$(starship init zsh)"

# Docker
export DOCKER_HOST=unix:///var/run/docker.sock

# x0.at - upload files to x0.at
function x0() {
	local file_name="${1##*/}"
	if [ -z "$file_name" ]; then
		echo "Usage: x0 <file>"
		return 1
	fi

	echo "Uploading $file_name to x0.at..."
	local url=$(curl -4 -# -f -F "file=@$1" https://x0.at 2>&1)
	local exit_code=$?

	if [ $exit_code -eq 0 ]; then
		echo "$url"
	else
		echo "Error: Upload failed (exit code: $exit_code)" >&2
		return $exit_code
	fi
}

# catbox - upload files to catbox.moe (permanent, 200MB max)
function catbox() {
	local file_name="${1##*/}"
	if [ -z "$file_name" ]; then
		echo "Usage: catbox <file>"
		return 1
	fi

	echo "Uploading $file_name to catbox.moe..."
	local url
	url=$(curl -4 -# -f -F "reqtype=fileupload" -F "fileToUpload=@$1" https://catbox.moe/user/api.php)
	local exit_code=$?

	if [ $exit_code -eq 0 ] && [ -n "$url" ]; then
		echo "$url"
	else
		echo "Error: Upload failed (exit code: $exit_code)" >&2
		return 1
	fi
}

# ============================================================
# Terminal Integration (OSC Escape Sequences)
# ============================================================

# OSC 7: Report CWD (for new_tab_with_cwd)
function __osc7_cwd() {
	printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
}

# OSC 2: Set window title to current directory
function __osc2_title() {
	printf '\e]2;%s\e\\' "${PWD/#$HOME/~}"
}

add-zsh-hook -Uz chpwd __osc7_cwd
add-zsh-hook -Uz chpwd __osc2_title

# Run once at shell start
__osc7_cwd
__osc2_title

# SSH wrapper for Kitty terminal compatibility
# Remote servers often don't have xterm-kitty terminfo, so we use xterm-256color
function ssh() {
	if [[ "$TERM" == "xterm-kitty" ]]; then
		TERM=xterm-256color command ssh "$@"
	elif [[ "$TERM" == "xterm-ghostty" ]]; then
		TERM=xterm-256color command ssh "$@"
	else
		command ssh "$@"
	fi
}

# Google Drive upload and auto-share
function gdr() {
	if [[ -z "$1" ]]; then
		echo "Usage: gdr <file>"
		return 1
	fi

	local file="$1"
	local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
	local pid file_id

	# Suppress job control messages
	setopt local_options no_monitor

	# Start upload in background
	gdrive files upload --print-only-id "$file" >/tmp/gdr_upload_$$ 2>&1 &
	pid=$!

	# Show spinner while uploading
	printf "  Uploading %s..." "$file"
	while kill -0 $pid 2>/dev/null; do
		for ((i = 0; i < ${#spinner}; i++)); do
			printf "\r%s Uploading %s..." "${spinner:$i:1}" "$file"
			sleep 0.1
			kill -0 $pid 2>/dev/null || break
		done
	done

	wait $pid
	local exit_code=$?
	file_id=$(<"/tmp/gdr_upload_$$")
	rm -f "/tmp/gdr_upload_$$"

	if [[ $exit_code -ne 0 || -z "$file_id" ]]; then
		printf "\r✗ Upload failed\n"
		[[ -n "$file_id" ]] && echo "$file_id"
		return 1
	fi

	# Share file silently
	if gdrive permissions share "$file_id" &>/dev/null; then
		printf "\r✓ https://drive.google.com/file/d/%s/view?usp=sharing\n" "$file_id"
	else
		printf "\r✗ Shared failed (uploaded: %s)\n" "$file_id"
		return 1
	fi
}

# Universal file opener (xdg-open wrapper)
function o() { xdg-open "$@" &>/dev/null & }

# restart system
function restart() {
	echo "Restarting system..."
	sudo reboot
	exit 0
}

alias reboot='restart'

# ============================================================
# URL Picker - Ghostty URL Hints Alternative
# ============================================================
# Extracts URLs from terminal scrollback and lets you select with fzf
# Similar to Kitty's Ctrl+Shift+E hints mode
#
# Usage:
#   url-pick          - Select & open URLs (from scrollback or manual input)
#   url-pick -m      - Select multiple URLs
#   url-pick -c      - Copy to clipboard instead of opening
#
# Keybinding: Ctrl+Alt+U (or Ctrl+Alt+E)
# ============================================================

autoload -Uz url-pick url-pick-multi url-copy urls openurl 2>/dev/null

function url-pick() {
  local urls selected
  
  # Try to get URLs from tmux scrollback if in tmux
  if [[ -n "$TMUX" ]]; then
    urls=$(tmux capture -p -S -10000 2>/dev/null | grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u)
  fi
  
  # If no URLs from tmux, try reading from stdin (piped input)
  if [[ -z "$urls" ]] && [[ ! -t 0 ]]; then
    urls=$(cat - | grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u)
  fi
  
  # If still no URLs, ask user to paste/input
  if [[ -z "$urls" ]]; then
    echo "No URLs found in scrollback. Paste URLs (one per line), then Ctrl+D:"
    urls=$(cat - | grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u)
  fi
  
  if [[ -z "$urls" ]]; then
    echo "No URLs found."
    return 1
  fi
  
  # Use fzf to select
  selected=$(echo "$urls" | fzf --prompt="Open URL: " --height=40% --reverse)
  
  [[ -z "$selected" ]] && return 0
  
  # Open in browser
  xdg-open "$selected" &>/dev/null &
  echo "Opening: $selected"
}

# Multi-select version
function url-pick-multi() {
  local urls selected
  
  if [[ -n "$TMUX" ]]; then
    urls=$(tmux capture -p -S -10000 2>/dev/null | grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u)
  fi
  
  if [[ -z "$urls" ]]; then
    echo "No URLs found in scrollback. Pipe URLs to this command:"
    echo "  echo 'https://example.com' | url-pick-multi"
    return 1
  fi
  
  selected=$(echo "$urls" | fzf --multi --prompt="Open URLs: " --height=40% --reverse)
  
  [[ -z "$selected" ]] && return 0
  
  echo "$selected" | while read -r url; do
    xdg-open "$url" &>/dev/null &
  done
  echo "Opened $(echo "$selected" | wc -l) URLs"
}

# Copy URL to clipboard
function url-copy() {
  local urls selected
  
  if [[ -n "$TMUX" ]]; then
    urls=$(tmux capture -p -S -10000 2>/dev/null | grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u)
  fi
  
  if [[ -z "$urls" ]]; then
    echo "No URLs found in scrollback."
    return 1
  fi
  
  selected=$(echo "$urls" | fzf --prompt="Copy URL: " --height=40% --reverse)
  
  [[ -z "$selected" ]] && return 0
  
  echo -n "$selected" | xclip -se c
  echo "Copied: $selected"
}

# Pipe-based URL extractor - works with any command output
# Usage: cat file.txt | urls
function urls() {
  grep -Eo '(https?://|ftp://|git@)[a-zA-Z0-9./?=_%:-]*' | grep -v '\.$' | sort -u | fzf --multi --prompt="Select URLs: "
}

# Simple URL opener - just prompts for URL
function openurl() {
  local url
  echo -n "Enter URL: "
  read url
  [[ -n "$url" ]] && xdg-open "$url" &>/dev/null && echo "Opening: $url"
}

# Keybinding: Ctrl+Alt+U
zle -N url-pick
zle -N url-pick-multi  
zle -N url-copy
bindkey '^eu' url-pick
bindkey '^eU' url-pick-multi
bindkey '^ec' url-copy
