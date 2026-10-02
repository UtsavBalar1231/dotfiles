#!/usr/bin/env bash
# Dotfiles installer for Arch, Debian and Ubuntu. Run ./install.sh --help.
set -Eeuo pipefail
shopt -s inherit_errexit

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STEPS=(preflight repos packages tools shell configs services post)
ROLES=(minimal dev desktop)
DISTROS=(arch debian ubuntu)

# shellcheck source=lib/common.sh
source "$REPO/lib/common.sh"
# shellcheck source=lib/versions.sh
source "$REPO/lib/versions.sh"
# shellcheck source=lib/os.sh
source "$REPO/lib/os.sh"
# shellcheck source=lib/packages.sh
source "$REPO/lib/packages.sh"
# shellcheck source=lib/pkg-arch.sh
source "$REPO/lib/pkg-arch.sh"
# shellcheck source=lib/pkg-apt.sh
source "$REPO/lib/pkg-apt.sh"
# shellcheck source=lib/steps/preflight.sh
source "$REPO/lib/steps/preflight.sh"
# shellcheck source=lib/steps/repos.sh
source "$REPO/lib/steps/repos.sh"
# shellcheck source=lib/steps/packages.sh
source "$REPO/lib/steps/packages.sh"
# shellcheck source=lib/steps/tools.sh
source "$REPO/lib/steps/tools.sh"
# shellcheck source=lib/steps/wayland-src.sh
source "$REPO/lib/steps/wayland-src.sh"
# shellcheck source=lib/steps/shell.sh
source "$REPO/lib/steps/shell.sh"
# shellcheck source=lib/steps/configs.sh
source "$REPO/lib/steps/configs.sh"
# shellcheck source=lib/steps/services.sh
source "$REPO/lib/steps/services.sh"
# shellcheck source=lib/steps/post.sh
source "$REPO/lib/steps/post.sh"

usage() {
	cat <<EOF
Usage: ./install.sh [options]

Options:
  --role minimal|dev|desktop     what to install (default: minimal; roles are cumulative)
  --gpu auto|amd|nvidia|intel|none
                                 GPU driver group (default: auto, from PCI; none in containers)
  --laptop | --no-laptop         laptop group (default: auto, from a battery being present)
  --with a,b                     optional groups: $(known_extras | paste -sd, - | sed 's/,/, /g')
  --only s1,s2 | --skip s1,s2    run only / skip these steps (preflight always runs)
  --dry-run                      print every command instead of running it (no sudo needed)
  --check                        install nothing; verify every selected package exists
  --yes                          do not ask before applying the plan
  --no-upgrade                   do not upgrade the system while installing packages
  --timezone Zone/Name           set the system timezone (e.g. Asia/Kolkata)
  --list                         show roles, groups and steps, then exit
  -h, --help                     show this help

Steps: ${STEPS[*]}
EOF
}

list() {
	local g d out aur
	header "Roles"
	echo "  minimal = base"
	echo "  dev     = base dev"
	echo "  desktop = base dev desktop"
	echo "  (+ gpu-<vendor>, laptop and --with extras)"
	header "Groups (packages per distro; Arch shows repo+AUR) from $PACKAGES_DIR"
	printf '  %-12s' group
	printf '%-12s' "${DISTROS[@]}"
	echo
	while read -r g; do
		printf '  %-12s' "$g"
		for d in "${DISTROS[@]}"; do
			out=$(group_packages "$d" "$g")
			if [[ $d == arch ]]; then
				aur=$(group_packages arch "$g.aur")
				printf '%-12s' "$(count_lines "$out")+$(count_lines "$aur")"
			else
				printf '%-12s' "$(count_lines "$out")"
			fi
		done
		echo
	done < <({ printf '%s\n' "${CORE_GROUPS[@]}"; known_extras; } | awk '!seen[$0]++')
	header "Steps"
	echo "  ${STEPS[*]}"
}

on_error() {
	local rc=$1 cmd=$2 where=$3
	# Inside run() the failing command is just "$@"; name the real one.
	[[ $cmd == '"$@"' ]] && cmd=${LAST_RUN:0:200}
	printf '%serror:%s step "%s" failed: %s exited with status %s (%s)\n' \
		"$C_RED" "$C_RESET" "${CURRENT_STEP:-startup}" "$cmd" "$rc" "$where" >&2
	printf 'log: %s\n' "$LOG_FILE" >&2
	exit "$rc"
}

split_csv() { tr ',' '\n' <<<"$1" | sed '/^$/d'; }

in_list() {
	local x=$1
	shift
	[[ " $* " == *" $x "* ]]
}

parse_args() {
	ROLE=minimal GPU=auto LAPTOP=auto DRY_RUN=0 CHECK=0 ASSUME_YES=0 NO_UPGRADE=0 TIMEZONE='' LIST=0
	EXTRAS=() ONLY=() SKIP=()
	while (($#)); do
		case $1 in
		--role | --gpu | --with | --only | --skip | --timezone)
			(($# >= 2)) || die "$1 needs a value"
			case $1 in
			--role) ROLE=$2 ;;
			--gpu) GPU=$2 ;;
			--with) mapfile -t -O "${#EXTRAS[@]}" EXTRAS < <(split_csv "$2") ;;
			--only) mapfile -t -O "${#ONLY[@]}" ONLY < <(split_csv "$2") ;;
			--skip) mapfile -t -O "${#SKIP[@]}" SKIP < <(split_csv "$2") ;;
			--timezone) TIMEZONE=$2 ;;
			esac
			shift
			;;
		--laptop) LAPTOP=1 ;;
		--no-laptop) LAPTOP=0 ;;
		--dry-run) DRY_RUN=1 ;;
		--check) CHECK=1 ;;
		--yes | -y) ASSUME_YES=1 ;;
		--no-upgrade) NO_UPGRADE=1 ;;
		--list) LIST=1 ;;
		-h | --help)
			usage
			exit 0
			;;
		*) die "unknown option '$1' (see --help)" ;;
		esac
		shift
	done

	in_list "$ROLE" "${ROLES[@]}" || die "--role must be one of: ${ROLES[*]}"
	in_list "$GPU" auto amd nvidia intel none || die "--gpu must be one of: auto amd nvidia intel none"
	local x
	local -a extras
	mapfile -t extras < <(known_extras)
	for x in "${EXTRAS[@]}"; do
		in_list "$x" "${extras[@]}" || die "unknown --with group '$x'; available: ${extras[*]}"
	done
	for x in "${ONLY[@]}" "${SKIP[@]}"; do
		in_list "$x" "${STEPS[@]}" || die "unknown step '$x'; steps: ${STEPS[*]}"
	done
	if [[ -n $TIMEZONE && ! $TIMEZONE =~ ^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)*$ ]]; then
		die "invalid --timezone '$TIMEZONE' (expected Zone/Name, e.g. Europe/Berlin)"
	fi
	((DRY_RUN + CHECK <= 1)) || die "--dry-run and --check cannot be combined"

	RUN_STEPS=()
	for x in "${STEPS[@]}"; do
		if [[ $x == preflight ]] || { { ((${#ONLY[@]} == 0)) || in_list "$x" "${ONLY[@]}"; } && ! in_list "$x" "${SKIP[@]}"; }; then
			RUN_STEPS+=("$x")
		fi
	done
}

main() {
	parse_args "$@"
	if ((LIST)); then
		list
		return 0
	fi

	ME=$(id -un)
	export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"
	local log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
	mkdir -p "$log_dir"
	LOG_FILE=$log_dir/install-$(date +%Y%m%d-%H%M%S).log
	exec > >(tee -a "$LOG_FILE") 2>&1
	TMP=$(mktemp -d -t dotfiles-install.XXXXXX)
	trap 'rm -rf "$TMP"' EXIT
	trap 'on_error $? "$BASH_COMMAND" "${BASH_SOURCE[0]}:$LINENO"' ERR

	CURRENT_STEP=preflight
	preflight_detect
	if ((CHECK)); then
		CURRENT_STEP=check
		show_plan
		check_packages
		return
	fi

	local s
	for s in "${RUN_STEPS[@]}"; do
		CURRENT_STEP=$s
		header "Step: $s"
		"step_$s"
	done
}

main "$@"
