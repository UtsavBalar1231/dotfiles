# shellcheck shell=bash
# Debian/Ubuntu desktop: build niri, eww, awww and xwayland-satellite from
# pinned tags when the distro does not provide them. Best effort: a failed
# build warns and the install carries on, because the rest of the system is
# still usable.

# Debian/Ubuntu packages each build needs, from each project's build instructions.
declare -A BUILD_DEPS=(
	[niri]="gcc clang pkg-config libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev libwayland-dev libinput-dev libdbus-1-dev libsystemd-dev libseat-dev libpipewire-0.3-dev libpango1.0-dev libdisplay-info-dev"
	[eww]="pkg-config libgtk-3-dev libgtk-layer-shell-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libcairo2-dev libglib2.0-dev libdbusmenu-gtk3-dev"
	[awww]="pkg-config liblz4-dev"
	[xwayland-satellite]="clang pkg-config libclang-dev libxcb1-dev libxcb-cursor-dev"
)
FAILED_BUILDS=()

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
	local -a deps=() words
	for m in "${missing[@]}"; do
		read -r -a words <<<"${BUILD_DEPS[$m]}"
		deps+=("${words[@]}")
	done
	mapfile -t deps < <(printf '%s\n' "${deps[@]}" | sort -u)
	info "Installing build dependencies for ${missing[*]}"
	if ! as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${deps[@]}"; then
		warn "could not install the build dependencies; skipping the source builds"
		FAILED_BUILDS+=("${missing[@]}")
		return 0
	fi
	for m in "${missing[@]}"; do
		info "Building $m from source (best effort; this takes a while)"
		if ! "build_$m"; then
			warn "building $m failed; install it manually (build log above)"
			FAILED_BUILDS+=("$m")
		fi
	done
	# shellcheck disable=SC2034  # read by step_post
	BUILT_WAYLAND_FROM_SOURCE=1
}
