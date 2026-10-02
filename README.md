# dotfiles

Post-install setup for Arch Linux, Debian and Ubuntu, plus the configs and a configuration backup of
my machines. One script installs a role (minimal, dev or desktop) with hardware and optional extras;
`bin/dotfiles` keeps the configs in `home/` in sync with `$HOME`.

## Quick start

```sh
git clone https://github.com/UtsavBalar1231/dotfiles ~/dotfiles && cd ~/dotfiles
./install.sh --list                                 # roles, groups and steps
./install.sh --role desktop --dry-run               # print every command, change nothing
./install.sh --role desktop --with gaming,apps      # shows the plan, asks, then installs
```

Run it as your normal user (it uses sudo where needed). Every step is safe to re-run.

## Supported systems

| Distro | Versions | Notes |
|---|---|---|
| Arch Linux | rolling | all roles; AUR packages through yay (bootstrapped as `yay-bin`) |
| Debian | 13 (trixie); 12 (bookworm) for minimal and dev | desktop builds niri, eww and awww from pinned sources; Debian 12 uses the adjusted lists in `packages/debian-12/` |
| Ubuntu | 24.04 and 26.04 LTS | same as Debian |

x86_64 is the main target; on aarch64, x86-only groups are skipped with a warning.

## Install options

```
./install.sh [options]
  --role minimal|dev|desktop     what to install (default: minimal; roles are cumulative)
  --gpu auto|amd|nvidia|intel|none
                                 GPU driver group (default: auto, from PCI; none in containers)
  --laptop | --no-laptop         laptop group (default: auto, from a battery being present)
  --with a,b                     optional groups: apps, embedded, gaming, virt
  --only s1,s2 | --skip s1,s2    run only / skip these steps (preflight always runs)
  --dry-run                      print every command instead of running it (no sudo needed)
  --check                        install nothing; verify every selected package exists
  --yes                          do not ask before applying the plan
  --no-upgrade                   do not upgrade the system while installing packages
  --timezone Zone/Name           set the system timezone (e.g. Asia/Kolkata)
```

**Roles** are cumulative: `minimal` is the shell and CLI tools (safe for servers), `dev` adds
toolchains, containers and linters, `desktop` adds the niri + eww Wayland desktop, fonts, theming and
the apps the desktop relies on. On top of a role come `gpu-amd|nvidia|intel`, `laptop`, and the
optional `--with` groups: `gaming`, `apps` (personal GUI apps), `virt` (QEMU/libvirt) and
`embedded` (cross toolchains, BSP and Android tools). What each group holds, and what Debian and
Ubuntu lack, is in [packages/README.md](packages/README.md).

**Steps**, in order:

| Step | Does |
|---|---|
| `preflight` | detects distro, CPU, GPU and battery; shows the plan; asks to continue |
| `repos` | Arch: enables `Color`, `VerbosePkgLists`, `ParallelDownloads` (only when unset) and `[multilib]` when a lib32 package is selected. Debian/Ubuntu: contrib/non-free or universe/multiverse, and i386 for gaming. Never enables testing or third-party repos |
| `packages` | Arch: `pacman -Syu --needed` (never a partial `-Sy`), then AUR packages with yay. Debian/Ubuntu: `apt-get install` |
| `tools` | what the repos lack, pinned and checksum-verified in `lib/versions.sh`: rustup, bun, uv, neovim, yazi and friends, Nerd Fonts, and the Wayland desktop builds on Debian/Ubuntu |
| `shell` | makes zsh your login shell (only yours, never root's); the zsh config installs its plugin manager on first start |
| `configs` | `bin/dotfiles deploy`: copies `home/` into `$HOME`, backing up anything it replaces |
| `services` | NetworkManager, bluetooth, ly, docker, power-profiles-daemon, fstrim (skipped without systemd) |
| `post` | the manual follow-ups (see below) and the log path |

The installer never touches the bootloader, kernel command line, mkinitcpio or the initramfs.
Logs go to `~/.local/state/dotfiles/install-<time>.log`. A failing command stops the run with the
step and command named; `--check` exits non-zero and lists every missing package.

**After installing:**

- **NVIDIA:** set up the driver's kernel parameters yourself if your setup needs them. Do not add the
  nvidia modules to the initramfs on the RTX 5090 machine; that hangs boot.
- **Wallpapers:** they are not in git. Copy them back into `~/Pictures/wallpapers`.
- **Secrets:** restore keys and tokens from your own backup of `private/` (see below).

## Configs: `bin/dotfiles`

`home/` mirrors the paths listed in [manifest/home.list](manifest/home.list) (relative to `$HOME`).
Files are copied, not symlinked, because the desktop theme rewrites some of them when the wallpaper
changes.

```sh
bin/dotfiles status             # what deploy and capture would each change
bin/dotfiles capture            # $HOME -> home/ (run this, review the diff, commit)
bin/dotfiles deploy             # home/ -> $HOME; shows the changes and asks first
bin/dotfiles deploy --dry-run   # list the changes only
```

`deploy` saves every file it replaces under `~/.local/state/dotfiles/backups/<time>/` and never
deletes anything in `$HOME`. To track another config, add its path to the manifest (with `!pattern`
excludes for caches or state) and run `capture`.

## Machine backups: `machines/` and `private/`

`scripts/snapshot.sh` (also `bin/dotfiles snapshot`) records the configuration of the machine it runs
on in `machines/<hostname>/`: package lists (pacman/apt, AUR, cargo, npm, bun, uv, pipx, go), enabled
services, every modified or unowned file in `/etc`, boot settings (for reference only), desktop
settings, hardware and system reports, and text configs the manifest does not cover. Re-run it to
refresh; the README it writes in each machine directory explains every file.

Anything secret goes to `private/machines/<hostname>/` instead: SSH and GPG keys, Wi-Fi profiles,
password hashes, host keys, tokens, and any file the secret scan flags. `private/` is git-ignored,
owner-only (700/600), and only exists on the machine that made it. Copy it to your own encrypted
backup if you want it elsewhere.

## Secrets

This repo is public, so secrets reach it only encrypted.

**Kept out of git, in four layers:**

1. **Never captured.** Secrets live in owner-only files the manifest skips (for example
   `~/.config/zsh/secrets.zsh`, sourced by `~/.zshenv`), and the snapshot routes anything
   secret-looking to `private/`, which `.gitignore` excludes.
2. **pre-commit** (`.githooks/`) refuses files under `private/`, anything in `secrets/` that is not
   an age-encrypted archive, and staged lines that look like a private key or access token.
3. **pre-push** re-checks every commit being pushed, so commits made with `--no-verify` are caught:
   `private/` paths, non-age files in `secrets/`, and secrets found by gitleaks (with
   `.gitleaks.toml`), or by the same patterns when gitleaks is not installed.
4. **GitHub** secret scanning and push protection are enabled on the repository, so GitHub itself
   rejects pushes that contain known token formats, even if the hooks were bypassed.

`bin/dotfiles` (and so `install.sh`) points each clone at these hooks
(`core.hooksPath = .githooks`) the first time it runs.

**Backing up.** `secrets/<hostname>.tar.age` holds `private/machines/<hostname>/` encrypted with
age and a passphrase (scrypt). It is committed and pushed with everything else, and it is exactly as
safe as the passphrase: use six or more random words, keep them in a password manager, and never
reuse them.

```sh
bin/dotfiles snapshot            # refresh machines/ and private/
bin/dotfiles secrets backup      # asks for the passphrase twice, writes secrets/<hostname>.tar.age
git add secrets machines && git commit -m "secrets: Update $(uname -n)"
```

**Restoring on a new machine:**

```sh
./install.sh --role desktop      # also installs age
bin/dotfiles secrets restore --dry-run    # asks for the passphrase, lists what it would do
bin/dotfiles secrets restore --system     # puts the secrets back
```

`restore` writes everything that belongs under `$HOME` (SSH and GPG keys, tokens, app logins)
with owner-only permissions and saves any file it replaces under
`~/.local/state/dotfiles/backups/`. `--system` adds the Wi-Fi profiles and the SSH host keys, with
sudo. It never restores `/etc/shadow` (it would overwrite the new system's accounts) or `/etc`
files whose original permissions were not recorded; for those, and for the desktop settings
(`dconf load`), decrypt everything with `bin/dotfiles secrets extract <dir>` and copy what you need.
On a machine with another hostname, add `--host <name>`.

## Layout

| Path | Holds |
|---|---|
| `install.sh`, `lib/` | the installer; `lib/steps/` has one file per step, `lib/versions.sh` every pinned download |
| `packages/` | package lists per distro and group |
| `bin/dotfiles`, `manifest/home.list` | config capture and deploy |
| `home/` | the captured configs |
| `scripts/snapshot.sh`, `machines/` | machine configuration backups |
| `scripts/secrets.sh`, `secrets/` | the age-encrypted secrets archives (`bin/dotfiles secrets`) |
| `.githooks/`, `.gitleaks.toml` | the commit and push guards against publishing secrets |
| `private/` | secrets from the snapshot (git-ignored) |
