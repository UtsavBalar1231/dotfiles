#!/usr/bin/env bash

debian_packages="
bc
bison
build-essential
bzip2
clang
curl
dwarves
flex
fzf
g++-multilib
gcc-multilib
gnupg
kitty
lib32ncurses-dev
libelf-dev
libncurses5-dev
libssl-dev
libxml2-utils
luarocks
p7zip-full
python-is-python3
python3
rsync
shellcheck
stow
svls
tmux
unzip
wget
xclip
xsel
xsltproc
zip
zlib1g-dev
zsh
"

arch_packages="
bat
bc
binutils
bison
btop
bzip2
clang
curl
ed
eza
fd
flex
fzf
gcc-libs
gnupg
gzip
kitty
libarchive
libelf
libtool
llvm
llvm-libs
luarocks
make
ncurses
neovim
nodejs
npm
patch
pkgconf
ripgrep
sed
shellcheck
stow
sudo
systemd
systemd-libs
texinfo
tmux
util-linux
wget
which
xclip
xsel
xz
zsh
"

if [ ! -f /etc/arch-release ]; then
	sudo apt update -y

	IFS=$'\n' read -rd ' ' -a packages <<<"$debian_packages"
	for package in "${packages[@]}"; do
		if ! dpkg -s "$package" >/dev/null 2>&1; then
			sudo apt install -y "$package"
		else
			echo "$package is already installed"
		fi
	done
else
	sudo pacman -Syu --noconfirm

	IFS=$'\n' read -rd ' ' -a packages <<<"$arch_packages"
	for package in "${packages[@]}"; do
		if ! pacman -Qi "$package" >/dev/null 2>&1; then
			sudo pacman -S --noconfirm "$package"
		else
			echo "$package is already installed"
		fi
	done
fi
