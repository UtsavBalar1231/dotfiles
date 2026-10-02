# shellcheck shell=bash
# Step 2: distro repository configuration (never testing or third-party repos).

step_repos() {
	case $DISTRO in
	arch) arch_repos ;;
	debian | ubuntu) apt_repos ;;
	esac
}
