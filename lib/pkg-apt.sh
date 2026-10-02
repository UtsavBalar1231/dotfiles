# shellcheck shell=bash
# Debian/Ubuntu: apt components, i386, package install, --check.

apt_sources_file() {
	local f
	for f in "/etc/apt/sources.list.d/$DISTRO.sources" /etc/apt/sources.list; do
		[[ -s $f ]] && { echo "$f"; return 0; }
	done
	return 1
}

# Components the selection needs beyond what the distro enables by default.
apt_components() {
	local wide=0
	[[ $ROLE == desktop || $GPU != none || " ${EXTRAS[*]} " == *" gaming "* ]] && wide=1
	case $DISTRO in
	debian) ((wide)) && echo main contrib non-free non-free-firmware || echo main ;;
	ubuntu) ((wide)) && echo main restricted universe multiverse || echo main universe ;;
	esac
}

wants_i386() {
	[[ " ${EXTRAS[*]} " == *" gaming "* && $(dpkg --print-architecture) == amd64 ]]
}

# apt_sources_render FILE COMPONENT...: print FILE with each component added
# to every deb822 "Components:" line or one-line "deb"/"deb-src" entry.
apt_sources_render() {
	local file=$1
	shift
	awk -v want="$*" '
	function add(prefix_fields,   n, w, i, j, have, out) {
		n = split(want, w, " ")
		out = $0
		for (i = 1; i <= n; i++) {
			have = 0
			for (j = prefix_fields; j <= NF; j++) if ($j == w[i]) have = 1
			if (!have) out = out " " w[i]
		}
		return out
	}
	/^Components:/ { print add(2); next }
	/^[ \t]*deb(-src)?[ \t]/ { print add(3); next }
	{ print }' "$file"
}

apt_repos() {
	local src
	src=$(apt_sources_file) || {
		warn "no $DISTRO apt sources file found; leaving apt sources alone"
		return 0
	}
	# shellcheck disable=SC2046  # component list is intentionally word-split
	apt_sources_render "$src" $(apt_components) >"$TMP/apt.sources"
	replace_root_file "$src" "$TMP/apt.sources"
	if wants_i386; then
		if dpkg --print-foreign-architectures | grep -qx i386; then
			ok "i386 architecture already enabled"
		else
			as_root dpkg --add-architecture i386
		fi
	fi
}

apt_packages() {
	as_root apt-get update
	[[ $NO_UPGRADE == 1 ]] || as_root env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
	if ((${#REPO_PKGS[@]})); then
		as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${REPO_PKGS[@]}"
	fi
}

# Print the names apt cannot install. Resolves against a private copy of the
# distro sources (with the components/architectures the repos step would add),
# so neither the system sources nor its package lists change.
apt_check() {
	local dir=$TMP/check-apt src out
	src=$(apt_sources_file) || die "no $DISTRO apt sources file found"
	mkdir -p "$dir/parts" "$dir/lists/partial" "$dir/cache/archives/partial"
	# shellcheck disable=SC2046
	apt_sources_render "$src" $(apt_components) >"$dir/parts/${src##*/}"
	[[ $src == *.sources ]] || mv "$dir/parts/${src##*/}" "$dir/sources.list"

	local -a opts=(
		-o "Dir::Etc::SourceList=$dir/sources.list" -o "Dir::Etc::SourceParts=$dir/parts"
		-o "Dir::State::Lists=$dir/lists" -o "Dir::Cache=$dir/cache" -o Debug::NoLocking=1
	)
	if wants_i386; then
		opts+=(-o "APT::Architectures::=$(dpkg --print-architecture)" -o APT::Architectures::=i386)
	fi

	info "Fetching a private copy of the package lists" >&2
	# Output only on failure: container images ship cleanup hooks that complain
	# about the system cache, which this private update does not use.
	if ! out=$(apt-get "${opts[@]}" -q update 2>&1); then
		printf '%s\n' "$out" >&2
		die "apt-get update of the private package lists failed"
	fi
	((${#REPO_PKGS[@]})) || return 0
	out=$(apt-get "${opts[@]}" -s install "${REPO_PKGS[@]}" 2>&1 || true)
	sed -n -e 's/^E: Unable to locate package //p' -e "s/^E: Package '\(.*\)' has no installation candidate/\1/p" <<<"$out"
	if awk '/^E: / && !/Unable to locate package|has no installation candidate/ { f = 1 } END { exit !f }' <<<"$out"; then
		printf '%s\n' "$out" >&2
		die "apt could not resolve the selected packages (see above)"
	fi
}
