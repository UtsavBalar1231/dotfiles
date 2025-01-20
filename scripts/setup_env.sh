#!/usr/bin/env bash

debian_packages="
autoconf
bc
bison
build-essential
bzip2
clang
cmake
curl
dwarves
flex
fzf
g++-multilib
gcc-multilib
gnupg
lib32ncurses-dev
libelf-dev
libncurses5-dev
libssl-dev
libxml2-utils
make
meson
p7zip-full
pkg-config
python-is-python3
python3
rsync
tmux
unzip
wget
xclip
xsel
xsltproc
zip
zlib1g-dev
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
fi
