# shellcheck shell=bash
# Arch Linux: pacman.conf/makepkg.conf edits, package install, yay, --check.

AUR_RPC=https://aur.archlinux.org/rpc/v5/info

needs_multilib() {
	local p
	for p in "${REPO_PKGS[@]}"; do
		[[ $p == lib32-* ]] && return 0
	done
	return 1
}

# pacman_conf_render FILE MULTILIB(0|1): print FILE with Color, VerbosePkgLists,
# ParallelDownloads (10 unless already set) and (when MULTILIB=1) the stock
# [multilib] section enabled. Every other section, testing repos included, is
# left untouched.
pacman_conf_render() {
	awk -v multilib="$2" '
	NR == FNR {
		if ($0 ~ /^#?[ \t]*Color[ \t]*$/) has_color = 1
		if ($0 ~ /^#?[ \t]*VerbosePkgLists[ \t]*$/) has_verbose = 1
		if ($0 ~ /^#?[ \t]*ParallelDownloads[ \t]*=/) has_parallel = 1
		if ($0 ~ /^#?[ \t]*\[multilib\][ \t]*$/) has_multilib = 1
		next
	}
	/^#?[ \t]*\[/ || /^[ \t]*$/ { in_multilib = 0 }
	/^#[ \t]*Color[ \t]*$/ { $0 = "Color" }
	/^#[ \t]*VerbosePkgLists[ \t]*$/ { $0 = "VerbosePkgLists" }
	/^#[ \t]*ParallelDownloads[ \t]*=/ { $0 = "ParallelDownloads = 10" }
	multilib && /^#[ \t]*\[multilib\][ \t]*$/ { $0 = "[multilib]"; in_multilib = 1; print; next }
	in_multilib && /^#[ \t]*Include[ \t]*=/ { sub(/^#[ \t]*/, "") }
	{ print }
	/^\[options\][ \t]*$/ && !options_done {
		options_done = 1
		if (!has_color) print "Color"
		if (!has_verbose) print "VerbosePkgLists"
		if (!has_parallel) print "ParallelDownloads = 10"
	}
	END {
		if (multilib && !has_multilib) print "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist"
	}' "$1" "$1"
}

# An existing MAKEFLAGS that already scales with $(nproc) is kept as is.
makepkg_conf_render() {
	# shellcheck disable=SC2016  # $(nproc) is evaluated by makepkg, not here
	awk -v line='MAKEFLAGS="-j$(nproc)"' '
	/^MAKEFLAGS=.*\$\(nproc\)/ { found = 1 }
	/^#?[ \t]*MAKEFLAGS=/ && !found { $0 = line; found = 1 }
	{ print }
	END { if (!found) print line }' "$1"
}

arch_repos() {
	local ml=0
	needs_multilib && ml=1
	pacman_conf_render /etc/pacman.conf "$ml" >"$TMP/pacman.conf"
	replace_root_file /etc/pacman.conf "$TMP/pacman.conf"
	makepkg_conf_render /etc/makepkg.conf >"$TMP/makepkg.conf"
	replace_root_file /etc/makepkg.conf "$TMP/makepkg.conf"
}

ensure_yay() {
	if have yay; then
		ok "yay already installed"
		return 0
	fi
	info "Bootstrapping yay-bin from the AUR"
	as_root pacman -S --needed --noconfirm base-devel git
	local dir
	dir=$(mktemp -d "$TMP/yay-bin.XXXXXX")
	run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$dir"
	(cd "$dir" && run makepkg -si --noconfirm)
}

arch_packages() {
	if [[ $NO_UPGRADE == 1 ]]; then
		if needs_multilib && [[ ! -e /var/lib/pacman/sync/multilib.db ]]; then
			die "[multilib] has no sync database yet; run once without --no-upgrade (a bare 'pacman -Sy' would be a partial upgrade)"
		fi
		if ((${#REPO_PKGS[@]})); then as_root pacman -S --needed --noconfirm "${REPO_PKGS[@]}"; fi
	else
		as_root pacman -Syu --needed --noconfirm "${REPO_PKGS[@]}"
	fi
	if ((${#AUR_PKGS[@]})); then
		ensure_yay
		run yay -S --needed --noconfirm --answerdiff None --answerclean None "${AUR_PKGS[@]}"
	fi
}

# Print the names that are in neither the repos (with [multilib] enabled) nor
# the AUR. Uses a private database under $TMP, so the system sync database is
# never refreshed (that would set up a partial upgrade).
arch_check() {
	local db=$TMP/check-db conf=$TMP/check-pacman.conf out
	local -a sync=(sudo)
	have fakeroot && sync=(fakeroot --)
	# An empty local database: resolve as on a fresh system, not against what
	# this machine happens to have installed.
	mkdir -p "$db/sync" "$db/local"
	pacman_conf_render /etc/pacman.conf 1 >"$conf"

	info "Syncing a private copy of the package databases" >&2
	"${sync[@]}" pacman -Sy --disable-sandbox --config "$conf" --dbpath "$db" --logfile /dev/null >/dev/null
	if ((${#REPO_PKGS[@]})); then
		out=$(pacman -Sp --config "$conf" --dbpath "$db" --print-format %n "${REPO_PKGS[@]}" 2>&1 >"$TMP/check-pacman.out" || true)
		sed -n 's/^error: target not found: //p' <<<"$out"
		if awk '/^error:/ && !/^error: target not found: / { f = 1 } END { exit !f }' <<<"$out"; then
			grep -v '^[a-z0-9]' "$TMP/check-pacman.out" >&2 || true
			printf '%s\n' "$out" >&2
			die "pacman could not resolve the selected packages (see above)"
		fi
	fi

	if ((${#AUR_PKGS[@]})); then
		local p found
		local -a args=()
		for p in "${AUR_PKGS[@]}"; do args+=(--data-urlencode "arg[]=$p"); done
		out=$(curl -fsSL --retry 3 -G "${args[@]}" "$AUR_RPC") || die "AUR RPC request failed: $AUR_RPC"
		found=$(grep -o '"Name":"[^"]*"' <<<"$out" | cut -d'"' -f4)
		for p in "${AUR_PKGS[@]}"; do
			grep -qxF -- "$p" <<<"$found" || echo "$p (aur)"
		done
	fi
}
