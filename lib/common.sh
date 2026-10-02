# shellcheck shell=bash
# Logging, command execution and small helpers shared by every module.

if [[ -t 1 ]]; then
	C_RESET=$'\e[0m' C_BOLD=$'\e[1m' C_BLUE=$'\e[34m' C_YELLOW=$'\e[33m' C_RED=$'\e[31m' C_GREEN=$'\e[32m'
else
	C_RESET='' C_BOLD='' C_BLUE='' C_YELLOW='' C_RED='' C_GREEN=''
fi

info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '%s ok%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%swarning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() {
	printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
	exit 1
}
header() { printf '\n%s%s:: %s%s\n' "$C_BOLD" "$C_BLUE" "$*" "$C_RESET"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Echo a command, then run it unless --dry-run. Its exit status is returned
# unchanged so set -e / the ERR trap see real failures.
run() {
	local cmd
	printf -v cmd '%q ' "$@"
	LAST_RUN=${cmd% }
	printf '%s+%s %s\n' "$C_BOLD" "$C_RESET" "$LAST_RUN"
	[[ $DRY_RUN == 1 ]] && return 0
	"$@"
}

as_root() { run sudo "$@"; }

confirm() {
	local reply
	[[ $ASSUME_YES == 1 ]] && return 0
	[[ -t 0 ]] || die "no terminal to ask for confirmation; re-run with --yes"
	read -r -p "$1 [y/N] " reply
	[[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

# pinned NAME -> value of NAME_<arch> (from lib/versions.sh); empty when that
# arch has no pin.
pinned() {
	local var="${1}_${ARCH}"
	printf '%s' "${!var:-}"
}

# fetch URL SHA256 DEST: download to DEST and verify, deleting it on mismatch.
fetch() {
	local url=$1 sum=$2 dest=$3
	run curl -fsSL --retry 3 --proto '=https' -o "$dest" "$url"
	[[ $DRY_RUN == 1 ]] && return 0
	if ! printf '%s  %s\n' "$sum" "$dest" | sha256sum -c --quiet - >/dev/null 2>&1; then
		rm -f "$dest"
		die "checksum mismatch for $url (expected $sum); update lib/versions.sh only after verifying upstream"
	fi
}

# Replace a root-owned config file with NEW_CONTENT_FILE when it differs,
# keeping a one-time backup at FILE.dotfiles-bak.
replace_root_file() {
	local file=$1 new=$2
	# Compared in bash: minimal images lack diffutils.
	if [[ "$(<"$file")" == "$(<"$new")" ]]; then
		ok "$file already configured"
		return 0
	fi
	if have diff; then diff -u "$file" "$new" || true; fi
	[[ -e $file.dotfiles-bak ]] || as_root cp -a "$file" "$file.dotfiles-bak"
	as_root install -m 644 -o root -g root "$new" "$file"
}
