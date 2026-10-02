# shellcheck shell=bash
# Package list parsing and role/group resolution.
#
# packages/<distro>/<group>.list (and arch/<group>.aur.list for the AUR):
#   one package per line, '#' comments, blank lines ignored,
#   '@include <distro>/<group>' pulls in another list (relative to packages/, no .list),
#   '-name' drops name from what this file has collected so far.
# A missing file is an empty group; files named _* are notes, never a group.

PACKAGES_DIR=${DOTFILES_PACKAGES_DIR:-$REPO/packages}
CORE_GROUPS=(base dev desktop gpu-amd gpu-nvidia gpu-intel laptop)
MAX_INCLUDE_DEPTH=8

_list_parse() {
	local file=$1 depth=$2 line inc n=0 p
	local -a words pkgs=() kept
	((depth <= MAX_INCLUDE_DEPTH)) || die "$file: @include nested more than $MAX_INCLUDE_DEPTH deep (include cycle?)"
	[[ -f $file ]] || return 0
	while IFS= read -r line || [[ -n $line ]]; do
		n=$((n + 1))
		read -r -a words <<<"${line%%#*}"
		((${#words[@]})) || continue
		if [[ ${words[0]} == @include ]]; then
			((${#words[@]} == 2)) || die "$file:$n: expected '@include <distro>/<group>'"
			inc=$(_list_parse "$PACKAGES_DIR/${words[1]}.list" $((depth + 1)))
			[[ -z $inc ]] || mapfile -t -O "${#pkgs[@]}" pkgs <<<"$inc"
			continue
		fi
		((${#words[@]} == 1)) || die "$file:$n: one package per line, got '${line%%#*}'"
		[[ ${words[0]} =~ ^-?[A-Za-z0-9@._+:-]+$ ]] || die "$file:$n: invalid package name '${words[0]}'"
		if [[ ${words[0]} == -* ]]; then
			kept=()
			for p in "${pkgs[@]}"; do
				[[ $p == "${words[0]#-}" ]] || kept+=("$p")
			done
			pkgs=("${kept[@]}")
		else
			pkgs+=("${words[0]}")
		fi
	done <"$file"
	((${#pkgs[@]} == 0)) || printf '%s\n' "${pkgs[@]}"
}

# group_packages DISTRO GROUP -> package names, one per line. GROUP may be
# "<name>.aur" for the AUR list on Arch.
group_packages() {
	_list_parse "$PACKAGES_DIR/$1/$2.list" 0
}

count_lines() {
	if [[ -z $1 ]]; then echo 0; else wc -l <<<"$1"; fi
}

# Optional groups for --with: gaming and apps plus any other non-core list.
known_extras() {
	local f g
	{
		printf '%s\n' gaming apps
		for f in "$PACKAGES_DIR"/*/*.list; do
			[[ -e $f ]] || continue
			g=${f##*/}
			g=${g%.list}
			g=${g%.aur}
			[[ $g == _* || " ${CORE_GROUPS[*]} " == *" $g "* ]] || echo "$g"
		done
	} | sort -u
}

# Sets SEL_GROUPS from ROLE, GPU, LAPTOP and EXTRAS.
select_groups() {
	SEL_GROUPS=(base)
	case $ROLE in
	dev) SEL_GROUPS+=(dev) ;;
	desktop) SEL_GROUPS+=(dev desktop) ;;
	esac
	[[ $GPU == none ]] || SEL_GROUPS+=("gpu-$GPU")
	[[ $LAPTOP == 0 ]] || SEL_GROUPS+=(laptop)
	if ((${#EXTRAS[@]})); then SEL_GROUPS+=("${EXTRAS[@]}"); fi

	# The lists treat these two groups as x86_64 only.
	if [[ $ARCH != x86_64 ]]; then
		local g
		local -a kept=()
		for g in "${SEL_GROUPS[@]}"; do
			if [[ $g == gaming || $g == gpu-nvidia ]]; then
				warn "skipping group $g: x86_64 only"
			else
				kept+=("$g")
			fi
		done
		SEL_GROUPS=("${kept[@]}")
	fi
}

# Sets REPO_PKGS and AUR_PKGS (deduplicated, in list order) for DISTRO/SEL_GROUPS.
resolve_packages() {
	local g out
	REPO_PKGS=()
	AUR_PKGS=()
	for g in "${SEL_GROUPS[@]}"; do
		out=$(group_packages "$DISTRO" "$g")
		[[ -z $out ]] || mapfile -t -O "${#REPO_PKGS[@]}" REPO_PKGS <<<"$out"
		if [[ $DISTRO == arch ]]; then
			out=$(group_packages arch "$g.aur")
			[[ -z $out ]] || mapfile -t -O "${#AUR_PKGS[@]}" AUR_PKGS <<<"$out"
		fi
	done
	if ((${#REPO_PKGS[@]})); then mapfile -t REPO_PKGS < <(printf '%s\n' "${REPO_PKGS[@]}" | awk '!seen[$0]++'); fi
	if ((${#AUR_PKGS[@]})); then mapfile -t AUR_PKGS < <(printf '%s\n' "${AUR_PKGS[@]}" | awk '!seen[$0]++'); fi
}
