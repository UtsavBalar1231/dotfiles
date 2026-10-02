# shellcheck shell=bash
# Distro, CPU and hardware detection.

# Sets DISTRO (arch|debian|ubuntu), DISTRO_NAME, DISTRO_VERSION and ARCH.
# Derivatives map through ID_LIKE.
detect_os() {
	[[ -r /etc/os-release ]] || die "cannot read /etc/os-release; unsupported system"

	local ID='' ID_LIKE='' PRETTY_NAME='' VERSION_ID=''
	# shellcheck disable=SC1091
	source /etc/os-release

	DISTRO=''
	local id
	for id in "$ID" $ID_LIKE; do
		case $id in
		arch | debian | ubuntu)
			DISTRO=$id
			break
			;;
		esac
	done
	[[ -n $DISTRO ]] || die "unsupported distro '$ID' (ID_LIKE='$ID_LIKE'); supported: arch, debian, ubuntu and their derivatives"

	DISTRO_NAME=${PRETTY_NAME:-$ID}
	DISTRO_VERSION=${VERSION_ID:-rolling}
	ARCH=$(uname -m)

	if [[ $DISTRO != "$ID" ]]; then
		warn "$DISTRO_NAME is treated as $DISTRO (best effort)"
	fi
	case "$DISTRO:$ID:$DISTRO_VERSION" in
	debian:debian:13* | ubuntu:ubuntu:24.04 | ubuntu:ubuntu:26.04 | arch:*) ;;
	debian:debian:12*) warn "Debian 12 is supported best effort; Debian 13 is the primary target" ;;
	debian:debian:* | ubuntu:ubuntu:*) warn "$DISTRO_NAME is not a tested release; continuing" ;;
	esac
	case $ARCH in
	x86_64 | aarch64) ;;
	*) warn "CPU architecture $ARCH is untested; pinned binaries will be skipped" ;;
	esac
}

in_container() {
	[[ -e /.dockerenv || -e /run/.containerenv ]] && return 0
	have systemd-detect-virt && systemd-detect-virt -q -c
}

has_systemd() { [[ -d /run/systemd/system ]]; }

# Discrete GPU wins over integrated when several are present.
detect_gpu() {
	if in_container; then
		echo none
		return
	fi
	local dev class vendor found=''
	for dev in /sys/bus/pci/devices/*; do
		[[ -r $dev/class ]] || continue
		class=$(<"$dev/class")
		[[ $class == 0x03* ]] || continue
		vendor=$(<"$dev/vendor")
		case $vendor in
		0x10de) found+=' nvidia' ;;
		0x1002) found+=' amd' ;;
		0x8086) found+=' intel' ;;
		esac
	done
	case $found in
	*nvidia*) echo nvidia ;;
	*amd*) echo amd ;;
	*intel*) echo intel ;;
	*) echo none ;;
	esac
}

detect_laptop() {
	compgen -G '/sys/class/power_supply/BAT*' >/dev/null
}
