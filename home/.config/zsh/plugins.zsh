# Plugin loading configuration - uses zi plugin manager with turbo mode

# Core plugins
zi ice wait lucid blockf depth'1'
zi light zsh-users/zsh-completions

# FZF integration
if command -v fzf &>/dev/null; then
  # fzf key bindings first (Ctrl-T, Alt-C, Ctrl-R)
  source <(fzf --zsh)
  # fzf-tab AFTER to override Tab binding in all keymaps (emacs + viins)
  zi ice lucid
  zi light Aloxaf/fzf-tab
fi

# Fish-like autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
zi ice wait lucid depth'1' atload"_zsh_autosuggest_start"
zi light zsh-users/zsh-autosuggestions

# Reminds you of existing aliases
zi ice wait"2" lucid depth'1'
zi light MichaelAquilina/zsh-you-should-use

# History substring search
zi ice lucid depth'1'
zi light zsh-users/zsh-history-substring-search

# Oh-My-Zsh plugins
zi ice wait lucid
zi snippet OMZ::plugins/git/git.plugin.zsh

zi ice wait lucid
zi snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

zi ice wait"1" lucid
zi snippet OMZ::plugins/extract/extract.plugin.zsh

zi ice wait"1" lucid
zi snippet OMZ::plugins/command-not-found/command-not-found.plugin.zsh

# Syntax highlighting
zi ice wait lucid atinit"zicompinit; zicdreplay"
zi light zdharma-continuum/fast-syntax-highlighting
