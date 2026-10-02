# shellcheck shell=bash
# Debian/Ubuntu desktop: build niri, eww, awww and xwayland-satellite from
# pinned tags when the distro does not provide them. Best effort: a failed
# build warns and the install carries on, because the rest of the system is
# still usable.

build_niri() { run cargo install --locked --git "$NIRI_GIT" --tag "$NIRI_TAG" niri; }
build_eww() { run cargo install --locked --git "$EWW_GIT" --rev "$EWW_REV" --no-default-features --features wayland eww; }
build_awww() { run cargo install --locked --git "$AWWW_GIT" --tag "$AWWW_TAG" awww awww-daemon; }
build_xwayland-satellite() { run cargo install --locked --git "$XWAYLAND_SATELLITE_GIT" --tag "$XWAYLAND_SATELLITE_TAG" xwayland-satellite; }

build_wayland_shell() {
	local m
	local -a missing=()
	for m in niri eww awww xwayland-satellite; do
		if have "$m"; then ok "$m already installed"; else missing+=("$m"); fi
	done
	((${#missing[@]})) || return 0
	if ! have cargo && [[ $DRY_RUN != 1 ]]; then
		warn "cargo is not available; cannot build ${missing[*]} from source"
		return 0
	fi
	for m in "${missing[@]}"; do
		info "Building $m from source (best effort; this takes a while)"
		"build_$m" || warn "building $m failed; install it manually (build log above)"
	done
	# shellcheck disable=SC2034  # read by step_post
	BUILT_WAYLAND_FROM_SOURCE=1
}
