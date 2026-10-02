# Package lists

One file per distro and group: `packages/<distro>/<group>.list`, with `distro` one of `arch`, `debian`, `ubuntu`.
Arch AUR packages live next to them in `<group>.aur.list` (installed with yay).

## Format

- One package per line. `#` starts a comment, on its own line or trailing. Blank lines are ignored.
- `@include <distro>/<group>` pulls in another list (path relative to `packages/`, no `.list`).
- `-name` removes `name` from what was included so far.
- A missing file is an empty group.
- Files starting with `_` are ignored by the installer. `arch/_excluded.list` documents every explicitly
  installed package of the reference machine that is deliberately in no group.

## Roles and groups

| Role | Groups |
|---|---|
| `minimal` | `base` |
| `dev` | `base`, `dev` |
| `desktop` | `base`, `dev`, `desktop` |

On top of the role: `gpu-<vendor>` for the selected GPU, `laptop` when a battery is present, and one list per
`--with` extra (`gaming`, `apps`, `virt`, `embedded`).

Ubuntu lists start with `@include debian/<group>`, then remove names that are missing on Ubuntu 24.04 or 26.04
and add Ubuntu-specific names. Every Ubuntu list resolves on both LTS releases. A name that exists on only one of
the two is removed and appears in the gaps table below.

## Groups

**base.** Headless-safe shell and CLI toolbox: zsh, tmux, neovim, ripgrep, fd, bat, eza, zoxide, fzf, yazi,
starship, git-delta, btop, archive tools, network and filesystem utilities. On Arch it also holds `base-devel`
and `git`, which the yay bootstrap needs. No GUI packages.

**dev.** Toolchains and linters: clang/LLVM, cmake, meson, ninja, gdb, Go, Node, Python tooling (pip, pipx,
pyenv, uv, mypy), Docker with buildx and compose, git-lfs (the `.gitconfig` requires the lfs filter), gh,
lazygit, shellcheck, shfmt, stylua, yamllint. Debian also lists the kernel-build dependencies from the old
scripts (`libelf-dev`, `libssl-dev`, `dwarves`, `bison`, `flex`, ...). Rust (rustup) and bun come from the
installer's tools step.

**desktop.** The runtime of the niri + eww shell. Everything `~/.config/niri/config.kdl` and
`~/.config/eww/scripts/*` call is covered: `wpctl` (wireplumber), `pactl` (libpulse / pulseaudio-utils),
`nmcli` (NetworkManager), `bluetoothctl` (bluez), `playerctl`, `udisksctl` (udisks2), `powerprofilesctl`,
`notify-send` (libnotify), `gsettings` (glib2), `ddcutil`, `ffmpeg`, `jq`, `gtk-launch` (gtk3), `xdg-open`,
`grim`/`slurp`/`wf-recorder`, `cliphist`/`wl-clipboard`, `swayidle`/`swaylock`, `ydotool`/`wtype`, and the
Python modules `gi` (Gio, GLib, Gtk, GdkPixbuf, Playerctl), `dbus` and `PIL`. It also holds audio, bluetooth and
network UIs, the portals, Nautilus/Loupe/File Roller (named in niri window rules), Qt platform plugins for
`qt5ct`/`qt6ct`, and the fonts and themes. On Arch the AUR half (`desktop.aur.list`) adds `eww-git`,
`orchis-theme-git`, `bibata-cursor-theme-bin`, `maplemono-nf`, `pwvucontrol` and the termfilechooser portal.
`ly` is the display manager on Arch. `power-profiles-daemon` is here because the eww bar reads it, and laptops
want it too.

**gpu-amd.** Mesa Vulkan/VA-API stack and `amdgpu_top` and ROCm SMI. Debian adds `firmware-amd-graphics`.

**gpu-nvidia.** Arch: `nvidia-open-dkms`, `nvidia-utils`, `nvidia-settings`, `dkms`, `linux-headers`,
`libva-nvidia-driver`, `lib32-nvidia-utils`. DKMS needs headers for every installed kernel, so install the
`*-headers` package matching a non-default kernel yourself. The installer never edits initramfs, mkinitcpio or
the kernel command line. Debian 13 ships driver 550, which cannot drive RTX 50 cards (see the gaps table).
Ubuntu uses the archive's `nvidia-driver-580-open`.

**gpu-intel.** Mesa Vulkan, the Intel media driver for VA-API (Arch also `lib32-vulkan-intel`).

**laptop.** Battery, backlight and CPU power tuning only: `acpi`, `brightnessctl`, `upower`, `cpupower`
(`linux-cpupower` on Debian, `linux-tools-*` on Ubuntu).

**gaming.** Steam, Wine, GameMode, MangoHud, GOverlay, peripheral configurators (`openrgb`, `piper`,
`libratbag`). Arch needs `[multilib]` (the installer enables it); Debian and Ubuntu need the i386 architecture.
x86-64 only: on aarch64 skip this group.

**apps.** Personal GUI apps and heavyweight document tooling: Firefox, VLC/mpv/MPD, LibreOffice, PDF viewers,
Inkscape, KiCad, qBittorrent, a few GNOME utilities, pandoc, mkdocs, PlantUML, TeX Live. Arch AUR half: Chrome,
Zen, Notion, Claude Desktop, Figma, LocalSend, remote-desktop clients, VS Code Insiders, Ventoy and similar.

**virt.** QEMU/KVM with libvirt and virt-manager, GNOME Boxes, QEMU user-mode emulation with binfmt for
foreign-architecture work, UEFI firmware for x86 and arm64 guests.

**embedded.** Cross-compilers (`aarch64-linux-gnu-gcc`), device-tree compiler, debootstrap/schroot/mkosi/rauc,
`repo`, squashfs tools, serial tools, Android SDK platform tools, JDKs, Debian packaging tools (debhelper,
lintian, git-buildpackage). The x86-only multilib bits of the old Debian list (`g++-multilib`,
`gcc-multilib`, `lib32ncurses-dev`) are left out because they do not exist on arm64; add them by hand for x86
kernel builds.

## Gaps on Debian/Ubuntu

Tools the roles need that the repos do not package, or package too old. The installer's `tools` step provides
them (pinned releases in `lib/versions.sh`). The "Lacks" column names the distros without a usable package:
D13 = Debian 13, U24 = Ubuntu 24.04, U26 = Ubuntu 26.04. A tool packaged on Debian 13 stays in `debian/*.list`;
the Ubuntu list removes it when either LTS lacks it. The tools step should therefore test `command -v` for every
tool below and install the ones still absent after the `packages` step.

| Tool | Role | Lacks | Suggested source |
|---|---|---|---|
| neovim (host runs 0.12; configs use 0.11 APIs) | base | D13 (0.10.4), U24 (0.9.5), U26 (0.11.6, borderline) | github.com/neovim/neovim release tarball (`nvim-linux-x86_64`, `nvim-linux-arm64`) |
| yazi | base | all | github.com/sxyazi/yazi release zip |
| zellij | base | all | github.com/zellij-org/zellij release tarball (musl) |
| starship | base | U24 | github.com/starship/starship release tarball (musl) |
| fastfetch | base | U24 | github.com/fastfetch-cli/fastfetch release `.deb` |
| glow | base | U24 | github.com/charmbracelet/glow release |
| tailscale | base | all | pkgs.tailscale.com apt repository (signed-by keyring) |
| diff-so-fancy | base | all | github.com/so-fancy/diff-so-fancy (one Perl script; low priority, `delta --diff-so-fancy` does not need it) |
| bun | dev | all | github.com/oven-sh/bun release zip |
| uv | dev | all | github.com/astral-sh/uv release tarball |
| ruff | dev | all | github.com/astral-sh/ruff release, or `uv tool install ruff` |
| nvm | dev | all | github.com/nvm-sh/nvm tagged install script (pinned, checksum) |
| stylua | dev | all | github.com/JohnnyMorganz/StyLua release |
| act | dev | all | github.com/nektos/act release |
| ast-grep | dev | all | github.com/ast-grep/ast-grep release |
| lazygit | dev | U24 | github.com/jesseduffield/lazygit release |
| eslint (distro has 6.x), markdownlint-cli2, corepack | dev | all | `npm install -g eslint markdownlint-cli2 corepack` |
| mdformat, pyenv | dev | U24 | `pipx install mdformat`; github.com/pyenv/pyenv |
| lua-jsregexp | dev | all | `luarocks install jsregexp` (nvim-snippet dependency) |
| niri | desktop | all | build the pinned tag from github.com/YaLTeR/niri (host runs 26.04); install the session files from `resources/` |
| eww | desktop | all | build github.com/elkowar/eww with `--no-default-features --features wayland`, pinned to the commit the shell was written against (host: 0.6.0.r87.g0e409d4) |
| awww | desktop | all | build the pinned tag from codeberg.org/LGFae/awww (host: 0.12.1; needs liblz4-dev, wayland dev packages) |
| xwayland-satellite | desktop | all | build github.com/Supreeeme/xwayland-satellite |
| ly | desktop | all | github.com/fairyglade/ly (needs Zig to build); packaged alternatives are `greetd` + `tuigreet` (D13, U26; `greetd` only on U24) |
| polkit-gnome agent | desktop | D13 | `policykit-1-gnome` on Ubuntu; on Debian `mate-polkit` is listed as the nearest packaged agent, but niri's `spawn-at-startup` path (`/usr/lib/polkit-gnome/...`) must change, or build polkit-gnome from gitlab.gnome.org |
| ydotool | desktop | D13 | github.com/ReimuNotMoe/ydotool (build v1.0.4); listed for Ubuntu |
| nwg-displays, nwg-look | desktop | U24 | github.com/nwg-piotr/nwg-displays (pip), github.com/nwg-piotr/nwg-look (go build) |
| resvg | desktop | U24 | github.com/linebender/resvg release |
| bluetui | desktop | all | github.com/pythops/bluetui release |
| ueberzugpp, viu (yazi image previews) | desktop | all | github.com/jstkdng/ueberzugpp; `cargo install viu`; optional |
| Tela circle icons | desktop | all | github.com/vinceliuice/Tela-circle-icon-theme `install.sh standard` |
| Orchis colour variants | desktop | all (distro package has only blue Orchis, Orchis-Dark, Orchis-Light) | github.com/vinceliuice/Orchis-theme `install.sh -t all -c dark`; `theme.py` picks Orchis-<Colour>-Dark |
| JetBrainsMono and Iosevka Nerd Fonts | desktop | all | github.com/ryanoasis/nerd-fonts releases (`JetBrainsMono.tar.xz`, `Iosevka.tar.xz`, check `SHA-256.txt`) |
| Maple Mono NF (first monospace choice in kitty, ghostty and fontconfig) | desktop | all | github.com/subframe7536/maple-font release `MapleMono-NF.zip` |
| pwvucontrol | desktop | all | Flatpak `com.saivert.pwvucontrol`; `pavucontrol` is listed as a fallback |
| xdg-desktop-portal-termfilechooser | desktop | all | build github.com/hunkyburrito/xdg-desktop-portal-termfilechooser (meson) |
| amdgpu_top | gpu-amd | all | github.com/Umio-Yasuno/amdgpu_top release `.deb` |
| NVIDIA driver 570+ (RTX 50 / Blackwell) | gpu-nvidia | D13 (550) | NVIDIA's own apt repository (CUDA repo for Debian, open kernel modules); the Ubuntu archive has 580-open |
| nvidia-vaapi-driver | gpu-nvidia | U24, U26 | build github.com/elFarto/nvidia-vaapi-driver (optional) |
| gamescope | gaming | D13, U24 | build github.com/ValveSoftware/gamescope (packaged on U26) |
| openrgb | gaming | D13, U24 | openrgb.org release `.deb` (packaged on U26) |
| protonup-qt | gaming | all | Flatpak `net.davidotek.pupgui2` |
| ghostty | apps | D13, U24 | build github.com/ghostty-org/ghostty (Zig); packaged on U26 |
| neovide | apps | all | github.com/neovide/neovide release |
| telegram-desktop | apps | all | Flatpak `org.telegram.desktop` or the tarball from telegram.org |
| bitwarden | apps | all | Bitwarden `.deb` from bitwarden.com or Flatpak `com.bitwarden.desktop` |
| papers | apps | U24 | Flatpak `org.gnome.Papers` (zathura is listed meanwhile) |
| d2, mermaid-cli, mpd-mpris, libresprite | apps | all | github.com/terrastruct/d2 release; `npm i -g @mermaid-js/mermaid-cli`; github.com/natsukagami/mpd-mpris (`go install`); github.com/LibreSprite/LibreSprite build |
| openjdk-17-jdk | embedded | D13 (has 21 and 25) | `openjdk-21-jdk` is listed; use Temurin 17 from adoptium.net where AOSP needs 17 |
| Arch AUR-only apps (Chrome, Zen, Notion, Claude Desktop, Figma, LocalSend, RustDesk, AnyDesk, TeamViewer, VS Code Insiders, Ventoy, Lark, WeMeet, Free Download Manager, gdrive) | apps | all | vendor `.deb` packages or Flatpak; not covered by the lists |

Other notes:

- `firefox` on Ubuntu is a transitional package that installs the Firefox snap. Debian lists `firefox-esr`.
- `bat` installs as `batcat` and `fd-find` as `fdfind` on Debian/Ubuntu; the shell config should add aliases.
- `hermes` (the hint-mode tool niri calls on `Mod+Semicolon`) is a custom binary in `/usr/local/bin` on the
  reference machine, not a package on any distro.
- aarch64: skip `gaming`, `gpu-nvidia` and the amd64-only items (i386 packages, `linux-headers-amd64`).

## Arch details

- Repo names were validated against `core`, `extra` and `multilib` only. Nothing in a list lives only in a testing
  repo, `kde-unstable`, `gnome-unstable` or the third-party `warpdotdev` repo.
- AUR names were validated with the AUR RPC. `freedownloadmanager` and `lintian` are flagged out of date there.
- Packages that exist both as a repo package and as the user's AUR/`-git` build use the repo package (`kitty`,
  `btop`, `telegram-desktop`, `pandoc-cli`), except where the AUR build is functionally different
  (`orchis-theme-git` ships every colour variant, `eww-git` has no repo package).
- `lib32-*` packages in `gpu-*` and `gaming` need `[multilib]`.
