# shellcheck shell=bash
# Step 4: installs that do not come from the package manager. Every download
# is pinned in lib/versions.sh and checksum-verified before use; each item is
# skipped when already present.

BIN_DIR=$HOME/.local/bin

extract() {
	local archive=$1 dir=$2
	run mkdir -p "$dir"
	if [[ $archive == *.zip ]]; then
		have unzip || [[ $DRY_RUN == 1 ]] || die "unzip is needed to unpack ${archive##*/}; it belongs in packages/$DISTRO/base.list"
		run unzip -q -o "$archive" -d "$dir"
	else
		run tar -xf "$archive" -C "$dir"
	fi
}

# install_release NAME DEST BIN...: fetch the pinned NAME archive for this
# arch and copy BIN... from it into DEST.
install_release() {
	local name=$1 dest=$2 url sum archive dir b src
	shift 2
	url=$(pinned "${name}_URL")
	sum=$(pinned "${name}_SHA256")
	if [[ -z $url ]]; then
		warn "no pinned ${name,,} build for $ARCH; skipping"
		return 0
	fi
	archive=$TMP/${url##*/}
	dir=$TMP/${name,,}
	fetch "$url" "$sum" "$archive"
	extract "$archive" "$dir"
	run mkdir -p "$dest"
	for b in "$@"; do
		src=$dir/$b
		if [[ $DRY_RUN != 1 ]]; then
			src=$(find "$dir" -type f -name "$b" -print -quit)
			[[ -n $src ]] || die "$b not found in ${url##*/}"
		fi
		run install -m 755 "$src" "$dest/$b"
	done
}

# tool CMD NAME DEST BIN...: install_release unless CMD is already on PATH.
tool() {
	if have "$1"; then
		ok "$1 already installed"
		return 0
	fi
	install_release "${@:2}"
}

install_neovim() {
	local dest=$HOME/.local/opt/nvim-$NVIM_VERSION url sum
	if [[ -x $dest/bin/nvim ]]; then
		ok "neovim $NVIM_VERSION already installed"
		return 0
	fi
	url=$(pinned NVIM_URL)
	sum=$(pinned NVIM_SHA256)
	[[ -n $url ]] || {
		warn "no pinned neovim build for $ARCH; skipping"
		return 0
	}
	fetch "$url" "$sum" "$TMP/nvim.tar.gz"
	run mkdir -p "$TMP/nvim" "${dest%/*}" "$BIN_DIR"
	run tar -xzf "$TMP/nvim.tar.gz" -C "$TMP/nvim" --strip-components=1
	run mv "$TMP/nvim" "$dest"
	run ln -sfn "$dest/bin/nvim" "$BIN_DIR/nvim"
}

install_rust() {
	if have rustup; then
		if rustup default >/dev/null 2>&1; then
			ok "rustup already installed"
		else
			run rustup default stable
		fi
		return 0
	fi
	local url sum
	url=$(pinned RUSTUP_URL)
	sum=$(pinned RUSTUP_SHA256)
	[[ -n $url ]] || {
		warn "no pinned rustup-init for $ARCH; skipping"
		return 0
	}
	fetch "$url" "$sum" "$TMP/rustup-init"
	run chmod +x "$TMP/rustup-init"
	# The deployed zsh config already puts ~/.cargo/bin on PATH.
	run "$TMP/rustup-init" -y --no-modify-path
}

install_fonts() {
	local f url sum archive dest added=0
	for f in "${FONTS[@]}"; do
		dest=$HOME/.local/share/fonts/$f
		if [[ -d $dest ]]; then
			ok "font $f already installed"
			continue
		fi
		url=FONT_URL_$f
		sum=FONT_SHA256_$f
		archive=$TMP/${!url##*/}
		fetch "${!url}" "${!sum}" "$archive"
		extract "$archive" "$TMP/font-$f"
		run mkdir -p "${dest%/*}"
		run mv "$TMP/font-$f" "$dest"
		added=1
	done
	if ((added)) && have fc-cache; then run fc-cache -f; fi
}

install_commit_msg_hook() {
	local hook=$HOME/.git/hooks/commit-msg
	if [[ -f $hook ]] && printf '%s  %s\n' "$COMMIT_MSG_SHA256" "$hook" | sha256sum -c --quiet - >/dev/null 2>&1; then
		ok "git commit-msg hook already installed"
		return 0
	fi
	fetch "$COMMIT_MSG_URL" "$COMMIT_MSG_SHA256" "$TMP/commit-msg"
	if [[ -e $hook && ! -e $hook.dotfiles-bak ]]; then run cp -a "$hook" "$hook.dotfiles-bak"; fi
	run install -D -m 755 "$TMP/commit-msg" "$hook"
}

step_tools() {
	have curl || [[ $DRY_RUN == 1 ]] || die "curl is required; it belongs in packages/$DISTRO/base.list"

	# What Debian/Ubuntu lack or ship too old (packages/README.md, "Gaps").
	if [[ $DISTRO != arch ]]; then
		install_neovim
		tool yazi YAZI "$BIN_DIR" yazi ya
		tool zellij ZELLIJ "$BIN_DIR" zellij
		tool starship STARSHIP "$BIN_DIR" starship
		tool fastfetch FASTFETCH "$BIN_DIR" fastfetch
		tool glow GLOW "$BIN_DIR" glow
		tool eza EZA "$BIN_DIR" eza
		tool zoxide ZOXIDE "$BIN_DIR" zoxide
	fi

	if [[ $ROLE != minimal ]]; then
		install_rust
		tool bun BUN "$HOME/.bun/bin" bun
		tool uv UV "$BIN_DIR" uv uvx
		if [[ $DISTRO != arch ]]; then
			tool lazygit LAZYGIT "$BIN_DIR" lazygit
			tool ruff RUFF "$BIN_DIR" ruff
		fi
	fi

	if [[ $ROLE == desktop && $DISTRO != arch ]]; then
		install_fonts
		build_wayland_shell
	fi

	install_commit_msg_hook
}
