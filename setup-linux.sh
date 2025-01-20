#!/usr/bin/env bash

CMD=$(realpath "${0}")
CUR_DIR=$(dirname "${CMD}")

# shellcheck source=scripts/utils.sh
source "${CUR_DIR}"/scripts/utils.sh

# shellcheck source=scripts/setup_shell.sh
bash "${CUR_DIR}"/scripts/setup_env.sh

# Build and install zsh from source
echo "Building ZSH from source, have patience!..."
git clone --depth=1 https://github.com/zsh-users/zsh /tmp/zsh
pushd /tmp/zsh
./Util/preconfig
./configure --enable-cflags=-O3
make -j$(nproc)
echo "Installing zsh..."
sudo make -j$(nproc) install

# Install kitty
echo "Installing kitty..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin installer=nightly && pkill kitty
if [ ! -d ~/.local/bin ]; then
    mkdir -p ~/.local/bin
fi
# Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in
# your system-wide PATH)
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
# Place the kitty.desktop file somewhere it can be found by the OS
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
# Update the paths to the kitty and its icon in the kitty desktop file(s)
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
# Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
echo 'kitty.desktop' > ~/.config/xdg-terminals.list

# Install vim
echo "Installing Vim..."
sudo apt install vim -y

# Install neovim
echo "Installing Neovim..."
if ! command -v add-apt-repository >/dev/null 2>&1; then
    sudo apt-get install software-properties-common
fi
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update -y
sudo apt-get install neovim -y


# Check if cargo is found
if ! command -v cargo >/dev/null 2>&1; then
    if [ -f ~/.cargo/env ]; then
        source ~/.cargo/env
    fi
fi

if command -v eza &>/dev/null; then
    echo "Installing eza..."
	cargo install eza 
fi

if command -v bat &>/dev/null; then
    echo "Installing bat..."
	cargo install bat
fi

if command -v fd &>/dev/null; then
    echo "Installing fd-find..."
	cargo install fd-find
fi

if command -v rg &>/dev/null; then
    echo "Installing ripgrep..."
	cargo install ripgrep
fi

if ! command -v cargo-update >/dev/null 2>&1; then
    echo "Installing cargo update..."
	cargo install cargo-update
fi

if ! command -v git-delta >/dev/null 2>&1; then
	cargo install git-delta
fi

if ! command -v zoxide >/dev/null 2>&1; then
	cargo install zoxide
fi

if ! command -v tree-sitter >/dev/null 2>&1; then
	cargo install tree-sitter-cli
fi

# Install diff-so-fancy: {{{
if ! command -v diff-so-fancy >/dev/null 2>&1; then
	echo "Installing diff-so-fancy..."
	diff_so_fancy_version=$(get_git_version "so-fancy/diff-so-fancy")

	curl -sLo ./diff-so-fancy https://github.com/so-fancy/diff-so-fancy/releases/download/"${diff_so_fancy_version}"/diff-so-fancy

	chmod a+x ./diff-so-fancy

	sudo mv ./diff-so-fancy /usr/local/bin/diff-so-fancy
fi
# }}}

# Install btop
ARCH=$(uname -m)
if ! command -v btop &>/dev/null; then
    echo "Installing btop..."
	if [[ $(get_ubuntu_version) -lt 23 ]]; then
		if [ "${ARCH}" = "x86_64" ]; then
			sudo cp -f "${CUR_DIR}"/prebuilts/btop-x86_64 /usr/local/bin/btop
		elif [ "${ARCH}" = "aarch64" ]; then
			sudo cp -f "${CUR_DIR}"/prebuilts/btop-aarch64 /usr/local/bin/btop
		else
			echo "btop not available for $(get_ubuntu_version) ${ARCH}"
		fi
	else
		sudo apt install -y btop
	fi
fi

# Configure zsh: {{{
echo "Setting up zsh..."
sudo chsh -s "$(which zsh)" $(whoami)
sudo chsh -s "$(which zsh)"

$(which zsh)
# }}}

# Setup fonts: {{{
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent

if [ -f ~/.local/bin/getnf ]; then
    ~/.local/bin/getnf -i "FiraCode","IBMPlexMono","IntelOneMono","Iosevka","JetBrainsMono","NerdFontsSymbolsOnly"
else
    echo "Failed to install nerd fonts..."
fi
# }}}

# Install nodejs
if [[ $(get_ubuntu_version) -lt 22 ]]; then
	curl -fsSL https://deb.nodesource.com/setup_19.x | sudo -E bash -
	sudo apt-get install -y nodejs npm
else
	sudo apt-get install -y nodejs npm
fi
