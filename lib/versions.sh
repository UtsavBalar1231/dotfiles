# shellcheck shell=bash
# Every pinned version, download URL and SHA-256 the installer uses.
#
# To bump a pin: change the version, update the URLs, download each file and put
# the output of `sha256sum <file>` here. Cross-check it against what upstream
# publishes (the .sha256 / checksums.txt / SHA-256.txt / SHASUMS256.txt next to
# the asset, or the "digest" field of the GitHub release API). Never point a URL
# at a moving target such as "latest", "main" or "nightly".
#
# Naming: <TOOL>_URL_<arch> and <TOOL>_SHA256_<arch>, arch = x86_64 | aarch64
# (the value of `uname -m`). A tool without an entry for an arch is skipped on it.
# shellcheck disable=SC2034  # the variables are read through ${!name} in lib/common.sh

# rustup-init from the versioned archive, so the checksum stays valid after new
# rustup releases. Published hash: <url>.sha256
RUSTUP_VERSION=1.29.1
RUSTUP_URL_x86_64="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init"
RUSTUP_SHA256_x86_64=dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71
RUSTUP_URL_aarch64="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/aarch64-unknown-linux-gnu/rustup-init"
RUSTUP_SHA256_aarch64=15f6e4ce9f583b929c996c91562bad6d4454f3281de858b02cdfdef615fac433

# Neovim release tarball (Debian/Ubuntu; their packaged nvim is too old).
# Published hash: GitHub release asset digest.
NVIM_VERSION=0.12.5
NVIM_URL_x86_64="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NVIM_SHA256_x86_64=bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875
NVIM_URL_aarch64="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-arm64.tar.gz"
NVIM_SHA256_aarch64=1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725

# Published hash: <url>.sha256
STARSHIP_VERSION=1.26.0
STARSHIP_URL_x86_64="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz"
STARSHIP_SHA256_x86_64=b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3
STARSHIP_URL_aarch64="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-aarch64-unknown-linux-musl.tar.gz"
STARSHIP_SHA256_aarch64=dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b

# Published hash: GitHub release asset digest. Zip archive (needs unzip).
YAZI_VERSION=26.9.1
YAZI_URL_x86_64="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-musl.zip"
YAZI_SHA256_x86_64=9b9c39decccf8cb0ff53a7d637d38f8a79d93bbd0099f4ea9c619ef6bb392f5d
YAZI_URL_aarch64="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-aarch64-unknown-linux-musl.zip"
YAZI_SHA256_aarch64=dd569daecaae914185f295634109295ccd25c1b42b02eb89a74f651970024f2e

# Published hash: checksums.txt
LAZYGIT_VERSION=0.65.1
LAZYGIT_URL_x86_64="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
LAZYGIT_SHA256_x86_64=02beacbcda0fa342e50ae3480ba8147307353af3fb28e1d5f790e02329c201a6
LAZYGIT_URL_aarch64="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_arm64.tar.gz"
LAZYGIT_SHA256_aarch64=49abecdf6adf4f2dfdb11bf7b9bfada267ea523612ed809d1c6d87f6c04000a7

# Published hash: GitHub release asset digest. No musl build for aarch64.
EZA_VERSION=0.23.5
EZA_URL_x86_64="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
EZA_SHA256_x86_64=e06eebab74b73d6b7d51a796a353824b001bea82df077706382e100815d28904
EZA_URL_aarch64="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_aarch64-unknown-linux-gnu.tar.gz"
EZA_SHA256_aarch64=40b87ae8628aa2ff0f0d2dc24ab52f689631366385c3da630bae745671fd71ec

# Published hash: GitHub release asset digest.
ZOXIDE_VERSION=0.10.0
ZOXIDE_URL_x86_64="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
ZOXIDE_SHA256_x86_64=2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae
ZOXIDE_URL_aarch64="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-aarch64-unknown-linux-musl.tar.gz"
ZOXIDE_SHA256_aarch64=f1f16c5d6298d63dee467eedea1cdcd8490e43e493bea43acd416dc9033ef641

# Published hash: SHASUMS256.txt. Zip archive (needs unzip).
BUN_VERSION=1.4.2
BUN_URL_x86_64="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip"
BUN_SHA256_x86_64=36368faef7527875d5ffa52e53cd48021741f2a83eb6208a8dd64068d422a913
BUN_URL_aarch64="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-aarch64.zip"
BUN_SHA256_aarch64=54328bbc2d9c8e0c9f892c544d66c57a83b84139e34909e5ee81758f1ac8fda7

# Published hash: <url>.sha256
UV_VERSION=0.12.22
UV_URL_x86_64="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
UV_SHA256_x86_64=b9980552309f09c15172b8be828555e375097f16deb459795ce7bfd200380f0b
UV_URL_aarch64="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-aarch64-unknown-linux-gnu.tar.gz"
UV_SHA256_aarch64=6f66a14e8239871fb477f9746c941fedfa77e8fe28a8bc7c07e1dc7f53a66712

# Published hash: GitHub release asset digest (and <asset>.sha256sum).
ZELLIJ_VERSION=0.45.1
ZELLIJ_URL_x86_64="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
ZELLIJ_SHA256_x86_64=40bcc2e03f5d5ae8e054e39f676081fe12ab70871506996ba595834c3718eefc
ZELLIJ_URL_aarch64="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-aarch64-unknown-linux-musl.tar.gz"
ZELLIJ_SHA256_aarch64=05f0802afadd53f8db9514e7cae53c9ae8432fed1b35b8294aa816ee3044a16b

# Published hash: GitHub release asset digest.
FASTFETCH_VERSION=2.69.0
FASTFETCH_URL_x86_64="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.tar.gz"
FASTFETCH_SHA256_x86_64=9fe880a34de3fec88e57a69230c02fd7be0846db3f3ea9f88f2b74489a79ff55
FASTFETCH_URL_aarch64="https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-aarch64.tar.gz"
FASTFETCH_SHA256_aarch64=843a0d4e3d604efc7cce18df1efcc09b00a1960cfea9949118b50bf999694027

# Published hash: checksums.txt
GLOW_VERSION=3.0.0
GLOW_URL_x86_64="https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_Linux_x86_64.tar.gz"
GLOW_SHA256_x86_64=13e05e4b2acc18d2aee44291aefe6325b077ec321b631a0cfa780e8e3bc33f78
GLOW_URL_aarch64="https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_Linux_arm64.tar.gz"
GLOW_SHA256_aarch64=810c39f4691feb75e675a5f5f54b9fa091354e7599d9cf9c9fc9b97e47a99759

# Published hash: <url>.sha256
RUFF_VERSION=0.16.10
RUFF_URL_x86_64="https://github.com/astral-sh/ruff/releases/download/${RUFF_VERSION}/ruff-x86_64-unknown-linux-musl.tar.gz"
RUFF_SHA256_x86_64=ad1b2138407a0c53b936524df99d87211333f7bc40478d6860f42994597f7ff0
RUFF_URL_aarch64="https://github.com/astral-sh/ruff/releases/download/${RUFF_VERSION}/ruff-aarch64-unknown-linux-musl.tar.gz"
RUFF_SHA256_aarch64=38ebc0ec3e0de538d1c399729ca04e124749211d66aa134c24ad0c1f09a935b9

# Fonts for Debian/Ubuntu desktop (arch independent), each unpacked into
# ~/.local/share/fonts/<name>. Nerd Fonts hash: SHA-256.txt of the release;
# Maple Mono hash: MapleMono-NF.sha256 next to the asset.
NERDFONTS_VERSION=3.5.1
MAPLEMONO_VERSION=7.9
FONTS=(JetBrainsMono Iosevka MapleMonoNF)
FONT_URL_JetBrainsMono="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/JetBrainsMono.tar.xz"
FONT_SHA256_JetBrainsMono=04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf
FONT_URL_Iosevka="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/Iosevka.tar.xz"
FONT_SHA256_Iosevka=3b94ea1dc3955756762f977b7677bca671947dd56bc755a6f8465a8e83b5f257
FONT_URL_MapleMonoNF="https://github.com/subframe7536/maple-font/releases/download/v${MAPLEMONO_VERSION}/MapleMono-NF.zip"
FONT_SHA256_MapleMonoNF=59098b87c895d871635d37680e88000ae2b2b25b55428195b228ec589e35fb89

# git commit-msg hook (Gerrit Change-Id), pinned to a gist revision. Upstream
# publishes no checksum; this one is the hash of that revision's content.
COMMIT_MSG_URL="https://gist.githubusercontent.com/UtsavBalar1231/c48cb6993ff45b077d41c13622fc27ba/raw/66f7da7f128a9511df81d624f23f87fc294b59b6/commit-msg"
COMMIT_MSG_SHA256=3fbf53898fd9c3ffd4ec056fed274eac3833a3325816aaf4ce1886ccdcffe861

# Wayland shell pieces built from source on Debian/Ubuntu desktop when the
# distro does not package them (cargo install --locked from these tags).
# eww is pinned to the commit the eww config was written against (0.6.0.r87).
NIRI_GIT=https://github.com/YaLTeR/niri.git
NIRI_TAG=v26.04
EWW_GIT=https://github.com/elkowar/eww.git
EWW_REV=0e409d4a52bd3d37d0aa0ad4e2d7f3b9a8adcdb7
AWWW_GIT=https://codeberg.org/LGFae/awww.git
AWWW_TAG=v0.12.1
XWAYLAND_SATELLITE_GIT=https://github.com/Supreeeme/xwayland-satellite.git
XWAYLAND_SATELLITE_TAG=v0.8.3
