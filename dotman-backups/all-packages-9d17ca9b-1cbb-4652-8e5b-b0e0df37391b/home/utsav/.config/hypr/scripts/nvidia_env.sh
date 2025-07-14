#!/usr/bin/env bash

declare -g config_name="$HOME/.config/hypr/conf/nvidia.conf"
[[ ! -e "$config_name" ]] && touch "$config_name"

if lspci | grep -qi "NVIDIA"; then
	cat <<-EOF >"$config_name"
		env = GBM_BACKEND, nvidia-drm
		env = LIBVA_DRIVER_NAME, nvidia
		env = NVD_BACKEND, direct
		env = SDL_VIDEODRIVER, wayland
		env = WLR_DRM_NO_ATOMIC, 1
		env = __GLX_VENDOR_LIBRARY_NAME, nvidia
		env = __NV_PRIME_RENDER_OFFLOAD, 1
		env = __VK_LAYER_NV_optimus, NVIDIA_only

		# nvidia firefox (for hardware acceleration on FF)
		env = EGL_PLATFORM, wayland
		env = MOZ_DISABLE_RDD_SANDBOX, 1
	EOF
else
	[[ -e "$config_name" ]] && rm "$config_name" && touch "$config_name"
fi
