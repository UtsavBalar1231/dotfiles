#!/usr/bin/env bash
# Re-runnable backup of this machine's configuration.
#
#   scripts/snapshot.sh              write machines/<hostname>/ (tracked, secret-free) and
#                                    private/machines/<hostname>/ (git-ignored, secrets only)
#   scripts/snapshot.sh --scan DIR   secret-scan DIR, print flagged paths only, exit 1 if any
#
# Both trees are built in a staging directory and swapped in at the end, so a failed run leaves
# the previous snapshot untouched. Output is sorted and free of timestamps except the README date
# (honours SOURCE_DATE_EPOCH). Nothing outside the repo is modified. Needs passwordless sudo
# (`sudo -n`) to read root-only files under /etc.
#
# Arch gets the full treatment (pacman lists, modified backup files, unowned /etc files). Debian
# and Ubuntu get apt package lists, modified conffiles and a curated /etc list. Any other distro
# gets the generic parts only.
#
# Secrets: every tracked file is scanned and anything that matches goes to private/ with the same
# relative path. The scan only ever prints paths, never matching lines.

set -Eeuo pipefail
export LC_ALL=C
umask 077

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
HOST=$(uname -n)
MAX_BYTES=1048576
PATH="$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"

STAGE=
PUB=
PRIV=
WORK=
FAMILY=other

log() { printf '[snapshot] %s\n' "$*" >&2; }
warn() { printf '[snapshot] warning: %s\n' "$*" >&2; }
die() {
    printf '[snapshot] error: %s\n' "$*" >&2
    exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }
as_root() { sudo -n "$@"; }

cleanup() {
    if [[ -n $STAGE && -d $STAGE ]]; then rm -rf "$STAGE"; fi
    return 0
}
trap cleanup EXIT
trap 'die "failed at line $LINENO (command: $BASH_COMMAND)"' ERR

readonly Q="'"

# Case-sensitive token shapes.
SCAN_CASE=(
    '-----BEGIN [A-Z0-9 ]*PRIVATE KEY'
    '(^|[^A-Za-z0-9])(AKIA|ASIA)[0-9A-Z]{16}'
    '(^|[^A-Za-z0-9])gh[pousr]_[A-Za-z0-9]{20,}'
    'github_pat_[A-Za-z0-9_]{20,}'
    'glpat-[A-Za-z0-9_-]{20,}'
    'xox[abpr]-[A-Za-z0-9-]{10,}'
    '(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}'
    'AIza[0-9A-Za-z_-]{35}'
    'npm_[A-Za-z0-9]{36}'
    'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
    '[Bb]earer [A-Za-z0-9._~+/=-]{20,}'
    '[a-z][a-z0-9+.-]*://[^/[:space:]:@]+:[^/[:space:]@]+@'
)

# Case-insensitive `password=...`, `wifi_psk: ...`, `token = "..."` assignments with a value of 8 or more characters.
SCAN_ICASE=(
    "(password|passwd|passphrase|passcode|psk|secret|token|api[_-]?key|access[_-]?key|auth[_-]?key|private[_-]?key|credentials?)[A-Za-z0-9_.-]*[\"$Q]?[[:space:]]*[:=][[:space:]]*[\"$Q]?[A-Za-z0-9+/=_.~!@#%^&*-]{8,}"
)

# Prints the files under $1 (relative paths) whose content matches a secret pattern.
scan_tree() {
    local dir=$1 pc pi
    pc=$(
        IFS='|'
        printf '%s' "${SCAN_CASE[*]}"
    )
    pi=$(
        IFS='|'
        printf '%s' "${SCAN_ICASE[*]}"
    )
    (
        cd "$dir"
        {
            grep -rIlE -e "$pc" . || true
            grep -rIliE -e "$pi" . || true
        } | sed 's|^\./||' | sort -u
    )
}

# The scan tolerates grep failures, so prove it still works before trusting an empty result.
scan_selftest() {
    local d pad hits
    d=$(mktemp -d)
    pad=$(printf 'x%.0s' {1..24})
    printf 'AKIA%s\n' "$(printf 'A%.0s' {1..16})" >"$d/aws"
    printf 'wifi_password = %s\n' "$pad" >"$d/assign"
    printf 'password = short\nname = value\n' >"$d/benign"
    hits=$(scan_tree "$d" | tr '\n' ' ')
    rm -rf "$d"
    [[ $hits == "assign aws " ]] || die "secret scan self-test failed (flagged: '$hits')"
}

# Names that hold credentials whatever their content.
secret_name() {
    local -
    shopt -s nocasematch
    case ${1##*/} in
    *.key | *.pem | *.p12 | *.pfx | *.jks | *.keystore | *.kdbx | *.keytab | *credential* | *secret* | *token* | *cookie* | *.aes | *master-key* | id_rsa* | id_ed25519* | id_ecdsa* | auth.json | auth.db* | .netrc | *.gpg) return 0 ;;
    esac
    return 1
}

# section OUT TITLE CMD...: append "## TITLE" and the command's stdout. A failing command leaves
# "(unavailable)" so a missing tool or session never aborts the run.
section() {
    local out=$1 title=$2
    shift 2
    {
        printf '## %s\n' "$title"
        "$@" 2>/dev/null || printf '(unavailable)\n'
        printf '\n'
    } >>"$out"
}

# Drop identifiers that must not appear in tracked reports: filesystem UUIDs and MAC addresses.
redact() {
    sed -E 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<uuid>/g; s/\b[0-9A-F]{4}-[0-9A-F]{4}\b/<uuid>/g; s/MAC\([0-9a-fA-F]+,/MAC(<mac>,/g'
}

# tar_copy ROOT DEST [root]: copy the NUL-separated paths on stdin (relative to ROOT) into DEST,
# keeping relative paths. "root" reads through sudo; copies end up owned by the caller. The
# archive goes through a file because tar exits 1 when a file changes while being read, which is
# tolerable, and a pipe would hide which side failed.
tar_copy() {
    local root=$1 dest=$2 mode=${3:-user} ar rc=0
    local -a pre=()
    [[ $mode == root ]] && pre=(sudo -n)
    ar=$(mktemp "$WORK/tar.XXXXXX")
    "${pre[@]}" tar --no-recursion --null -C "$root" -T - -cf - >"$ar" || rc=$?
    ((rc <= 1)) || die "tar failed (exit $rc) while reading from $root"
    mkdir -p "$dest"
    tar -C "$dest" -xf "$ar"
    rm -f "$ar"
}

# drop_binaries DIR PREFIX OUT: delete binary files from DIR (relative paths, NUL-separated, on
# stdin) and append "PREFIX<path><TAB>binary" to OUT.
drop_binaries() {
    local dir=$1 prefix=$2 out=$3 rel
    while IFS= read -r -d '' rel; do
        [[ -f $dir/$rel ]] || continue
        if [[ -s $dir/$rel ]] && ! grep -Iq '' "$dir/$rel"; then
            rm -f "$dir/$rel"
            printf '%s%s\tbinary\n' "$prefix" "$rel" >>"$out"
        fi
    done
}

# swap_in NEW TARGET: replace TARGET with NEW; put the old TARGET back if the rename fails.
swap_in() {
    local new=$1 target=$2 old
    old=$STAGE/old.$RANDOM
    mkdir -p "$(dirname "$target")"
    if [[ -e $target ]]; then mv -T "$target" "$old"; fi
    if ! mv -T "$new" "$target"; then
        if [[ -e $old ]]; then mv -T "$old" "$target"; fi
        die "could not install $target"
    fi
}

os_value() { (
    # shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null
    printf '%s' "${!1-}"
); }

sys_hostnamectl() { hostnamectl | grep -viE 'machine id|boot id|serial|asset tag'; }
sys_cmdline() { redact </proc/cmdline; }
sys_timezone() {
    if have timedatectl; then
        timedatectl show -p Timezone -p LocalRTC -p NTP
    else
        cat /etc/timezone
    fi
}
sys_lsblk() {
    lsblk -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS 2>/dev/null ||
        lsblk -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINT
}
sys_findmnt() {
    local first
    {
        IFS= read -r first
        printf '%s\n' "$first"
        sort
    } < <(findmnt -l | redact | grep -vE '^(/run/(docker|user|credentials|netns)|/var/lib/(docker|containers)|/snap/)')
}

gen_system() {
    local f=$PUB/system.txt
    : >"$f"
    section "$f" 'hostnamectl (machine and boot ids omitted)' sys_hostnamectl
    section "$f" '/etc/os-release' cat /etc/os-release
    section "$f" 'uname -a' uname -a
    section "$f" '/proc/cmdline (UUIDs redacted)' sys_cmdline
    section "$f" 'timezone' sys_timezone
    section "$f" 'locale' localectl status
    section "$f" 'lsblk -f (UUID column omitted)' sys_lsblk
    section "$f" 'findmnt -l (UUIDs redacted; container and per-user runtime mounts omitted)' sys_findmnt
    section "$f" 'swap' swapon --show=NAME,TYPE,SIZE,PRIO
    section "$f" 'zram' zramctl --output NAME,DISKSIZE,ALGORITHM,STREAMS
}

hw_dmi() {
    local k
    for k in sys_vendor product_name product_version board_vendor board_name bios_vendor bios_version bios_date; do
        if [[ -r /sys/class/dmi/id/$k ]]; then printf '%s: %s\n' "$k" "$(</sys/class/dmi/id/$k)"; fi
    done
}
hw_lscpu() { lscpu | grep -vE '^(Flags|Vulnerabilit|NUMA node[0-9]|CPU op-mode|Byte Order|Address sizes|BogoMIPS|Model:|Stepping|CPU max|CPU min|CPU MHz|CPU\(s\) scaling)' | sed -E 's/[[:space:]]+$//'; }
hw_mem() { grep -E '^(MemTotal|SwapTotal):' /proc/meminfo; }
hw_lspci() { lspci -nnk | redact; }
hw_lsusb() { lsusb | sed -E 's/^Bus ([0-9]+) Device [0-9]+: /Bus \1: /' | sort; }
hw_gpu_lines() { lspci -nn | grep -Ei 'vga compatible|3d controller|display controller' | sed -E 's/^[^ ]+ //'; }
hw_nvidia() { nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader; }

# niri's JSON carries each monitor's serial number; blank it before anything is written.
hw_monitors() {
    local sock=${NIRI_SOCKET:-}
    if [[ -z $sock ]]; then
        sock=$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}" -maxdepth 1 -name 'niri.*.sock' 2>/dev/null | sort | head -n1)
    fi
    have niri && [[ -n $sock ]] || return 1
    NIRI_SOCKET=$sock niri msg --json outputs |
        sed -E 's/("serial"[[:space:]]*:[[:space:]]*)"[^"]*"/\1null/g' |
        if have jq; then jq -S .; else cat; fi
}

gen_hardware() {
    local f=$PUB/hardware.txt
    : >"$f"
    section "$f" 'DMI (serial numbers omitted)' hw_dmi
    section "$f" 'lscpu (summary)' hw_lscpu
    section "$f" 'memory' hw_mem
    section "$f" 'GPU' hw_gpu_lines
    if have nvidia-smi; then section "$f" 'nvidia-smi (name, driver, memory)' hw_nvidia; fi
    section "$f" 'lspci -nnk (UUIDs redacted)' hw_lspci
    section "$f" 'lsusb (bus numbers only)' hw_lsusb
    section "$f" 'monitors (niri msg --json outputs, serials omitted)' hw_monitors
}

# pkg_list FILE CMD...: write the sorted stdout of CMD to packages/FILE when CMD succeeds.
pkg_list() {
    local name=$1 out
    shift
    out=$(
        set -o pipefail
        "$@" 2>/dev/null | sort
    ) || return 0
    printf '%s\n' "$out" >"$PUB/packages/$name"
}

npm_global() { npm ls -g --depth=0 --parseable --long | sed -n 's|^.*node_modules/[^:]*:||p'; }
bun_global() { bun pm ls -g | awk '/@/ { print $NF }'; }
go_bin() {
    local dir f
    dir=$(go env GOBIN)
    [[ -n $dir ]] || dir=$(go env GOPATH)/bin
    [[ -d $dir ]] || return 0
    for f in "$dir"/*; do
        [[ -f $f ]] || continue
        printf '%s\t%s\n' "${f##*/}" "$(go version -m "$f" 2>/dev/null | awk '$1 == "path" { p = $2 } $1 == "mod" { m = $2 "@" $3 } END { print p, m }')"
    done
}
flatpak_list() { flatpak list --columns=application,branch,origin,installation; }

gen_packages() {
    mkdir -p "$PUB/packages"
    case $FAMILY in
    arch)
        have pacman || die "pacman not found on an Arch-family system"
        pkg_list pacman-native.txt pacman -Qqen
        pkg_list pacman-foreign.txt pacman -Qqem
        pkg_list pacman-all.txt pacman -Q
        ;;
    debian)
        pkg_list apt-manual.txt apt-mark showmanual
        # shellcheck disable=SC2016 # dpkg-query expands the ${...} fields itself
        pkg_list dpkg-all.txt dpkg-query -W -f '${Package}\t${Version}\n'
        if have snap; then pkg_list snap.txt snap list; fi
        ;;
    *) warn "no package manager support for '$(os_value ID)'; skipping system package lists" ;;
    esac
    if have cargo; then pkg_list cargo.txt cargo install --list; fi
    if have npm; then pkg_list npm-global.txt npm_global; fi
    if have bun; then pkg_list bun-global.txt bun_global; fi
    if have uv; then pkg_list uv-tools.txt uv tool list; fi
    if have pipx; then pkg_list pipx.txt pipx list --short; fi
    if have go; then pkg_list go-bin.txt go_bin; fi
    if have flatpak; then pkg_list flatpak.txt flatpak_list; fi
}

# unit_files FILE SCOPE STATE [TYPE]: append one "## SCOPE" block of unit files in STATE.
unit_files() {
    local out=$1 scope=$2 state=$3 type=${4:-} list
    local -a ctl=(systemctl) args=(list-unit-files --no-legend --no-pager "--state=$state")
    [[ $scope == user ]] && ctl+=(--user)
    [[ -n $type ]] && args+=("--type=$type")
    {
        printf '## %s\n' "$scope"
        if list=$("${ctl[@]}" "${args[@]}" 2>/dev/null) || "${ctl[@]}" show --property=Version >/dev/null 2>&1; then
            awk 'NF { print $1 "\t" $2 "\t" $3 }' <<<"$list" | sort
        else
            printf '(unavailable)\n'
        fi
        printf '\n'
    } >>"$out"
}

gen_services() {
    local d=$PUB/services scope
    if ! have systemctl; then
        warn "systemctl not found; skipping services"
        return 0
    fi
    mkdir -p "$d"
    : >"$d/enabled.txt"
    : >"$d/timers.txt"
    : >"$d/masked.txt"
    for scope in system user; do
        unit_files "$d/enabled.txt" "$scope" enabled
        unit_files "$d/timers.txt" "$scope" enabled timer
        unit_files "$d/masked.txt" "$scope" masked
    done
}

# Prints the privacy-safe group name for files that are always secret, whoever owns them.
private_etc_group() {
    case $1 in
    /etc/shadow | /etc/shadow- | /etc/gshadow | /etc/gshadow- | /etc/brlapi.key | /etc/ipsec.secrets) printf '%s\n' "$1" ;;
    /etc/ssh/ssh_host_*) printf '%s\n' '/etc/ssh/ssh_host_*' ;;
    /etc/NetworkManager/system-connections/*) printf '%s\n' '/etc/NetworkManager/system-connections/' ;;
    /etc/wireguard/*) printf '%s\n' '/etc/wireguard/' ;;
    /etc/ssl/private/*) printf '%s\n' '/etc/ssl/private/' ;;
    /etc/openvpn/*) printf '%s\n' '/etc/openvpn/' ;;
    *) return 1 ;;
    esac
}

# Generated, regenerable and backup files: not configuration worth keeping.
etc_noise() {
    case $1 in
    /etc/ca-certificates/* | /etc/ssl/certs/* | /etc/pki/* | /etc/pacman.d/gnupg/*) return 0 ;;
    /etc/ld.so.cache | /etc/udev/hwdb.bin | /etc/machine-id | /etc/.updated | /etc/.pwd.lock) return 0 ;;
    /etc/blkid.tab | /etc/blkid.tab.old | /etc/texmf/ls-R | /etc/xml/catalog) return 0 ;;
    /etc/*/cache/* | *.cache | *.lock | *~ | *-) return 0 ;;
    *.bak | *.bak-* | *.bak.* | *.backup | *.backup.* | *.orig | *.OLD | *.old) return 0 ;;
    *.pacnew | *.pacsave | *.pacorig | *.dpkg-* | *.ucf-*) return 0 ;;
    esac
    return 1
}

ETC_CURATED=(
    /etc/fstab /etc/crypttab /etc/hosts /etc/hostname /etc/locale.gen /etc/locale.conf
    /etc/default/locale /etc/default/keyboard /etc/default/grub /etc/environment /etc/timezone
    /etc/vconsole.conf /etc/apt/sources.list /etc/apt/sources.list.d /etc/apt/apt.conf.d
    /etc/apt/preferences /etc/apt/preferences.d /etc/sudoers.d /etc/ssh/sshd_config
    /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d /etc/sysctl.conf /etc/sysctl.d /etc/modprobe.d
    /etc/modules /etc/modules-load.d /etc/udev/rules.d /etc/systemd/system /etc/systemd/network
    /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d /etc/systemd/journald.conf.d
    /etc/systemd/logind.conf.d /etc/systemd/zram-generator.conf /etc/NetworkManager/NetworkManager.conf
    /etc/NetworkManager/conf.d /etc/X11/xorg.conf.d /etc/docker/daemon.json /etc/netplan
    /etc/profile.d /etc/cron.d /etc/initramfs-tools/initramfs.conf /etc/initramfs-tools/modules
    /etc/security/limits.d /etc/polkit-1/rules.d /etc/tmpfiles.d /etc/ufw/ufw.conf
)

etc_curated() {
    local p
    for p in "${ETC_CURATED[@]}"; do
        as_root find "$p" -xdev -type f 2>/dev/null || true
    done | sort -u
}

# Arch: "path<TAB>modified:<package>" for every backup file pacman reports as "path [modified]".
etc_modified_pacman() {
    as_root pacman -Qii | awk '
        /^Name[[:space:]]*:/ { pkg = $3; inb = 0; next }
        /^[A-Za-z]/ { inb = ($0 ~ /^Backup Files/) }
        inb {
            line = $0
            sub(/^Backup Files[[:space:]]*:[[:space:]]*/, "", line)
            sub(/^[[:space:]]+/, "", line)
            if (line ~ /^\/.* \[modified\]$/) { sub(/ \[modified\]$/, "", line); print line "\tmodified:" pkg }
        }'
}

# Debian: conffiles whose md5 differs from the one dpkg recorded.
etc_modified_dpkg() {
    local sums=$WORK/dpkg-conffiles.tsv failed=$WORK/dpkg-failed.txt
    dpkg-query -W -f '${binary:Package}\n${Conffiles}\n' |
        awk '/^ / { if ($2 ~ /^[0-9a-f]{32}$/) print $1 "\t" $2 "\t" pkg; next } NF { pkg = $1 }' | sort -u >"$sums"
    awk -F'\t' '{ print $2 "  " $1 }' "$sums" | as_root md5sum -c 2>/dev/null | sed -n 's/: FAILED$//p' | sort -u >"$failed" || true
    awk -F'\t' 'NR == FNR { bad[$0] = 1; next } ($1 in bad) { print $1 "\tmodified:" $3 }' "$failed" "$sums"
}

gen_etc() {
    local d=$PUB/etc all=$WORK/etc-all.tsv cand=$WORK/etc-cand.tsv
    local skipped=$d/SKIPPED.txt path kind typ size g
    mkdir -p "$d"
    : >"$skipped"
    : >"$WORK/etc-index.tsv"
    : >"$WORK/etc-copy.list"
    : >"$WORK/etc-private.list"
    : >"$WORK/etc-private-groups.txt"

    as_root find /etc -xdev \( -type f -o -type l \) -printf '%y\t%s\t%p\n' | sort -t$'\t' -k3,3 >"$all"
    declare -A ETYPE=() ESIZE=()
    while IFS=$'\t' read -r typ size path; do
        ETYPE[$path]=$typ
        ESIZE[$path]=$size
    done <"$all"

    {
        case $FAMILY in
        arch)
            etc_modified_pacman
            pacman -Qlq | awk '/^\/etc\//' | sort -u >"$WORK/etc-owned.txt"
            awk -F'\t' '$1 == "f" { print $3 }' "$all" | sort | comm -23 - "$WORK/etc-owned.txt" | awk '{ print $0 "\tunowned" }'
            ;;
        debian)
            etc_modified_dpkg
            etc_curated | awk '{ print $0 "\tcurated" }'
            ;;
        *) etc_curated | awk '{ print $0 "\tcurated" }' ;;
        esac
    } | awk -F'\t' '!seen[$1]++' | sort -t$'\t' -k1,1 >"$cand"

    for path in "${!ETYPE[@]}"; do
        [[ ${ETYPE[$path]} == f ]] || continue
        if g=$(private_etc_group "$path"); then
            printf '%s\n' "$path" >>"$WORK/etc-private.list"
            printf '%s\n' "$g" >>"$WORK/etc-private-groups.txt"
        fi
    done

    while IFS=$'\t' read -r path kind; do
        [[ -n ${ETYPE[$path]:-} ]] || continue
        if private_etc_group "$path" >/dev/null || etc_noise "$path"; then continue; fi
        if secret_name "$path"; then
            printf '%s\n' "$path" >>"$WORK/etc-private.list"
            printf '%s\tprivate\n' "$path" >>"$WORK/etc-index.tsv"
        elif [[ ${ETYPE[$path]} == l ]]; then
            printf '%s\tsymlink -> %s\n' "$path" "$(as_root readlink "$path")" >>"$skipped"
        elif ((ESIZE[$path] > MAX_BYTES)); then
            printf '%s\t>1MB\n' "$path" >>"$skipped"
        else
            printf '%s\0' "${path#/}" >>"$WORK/etc-copy.list"
            printf '%s\t%s\n' "$path" "$kind" >>"$WORK/etc-index.tsv"
        fi
    done <"$cand"

    if [[ -s $WORK/etc-copy.list ]]; then
        tar_copy / "$PUB" root <"$WORK/etc-copy.list"
        drop_binaries "$PUB" / "$skipped" <"$WORK/etc-copy.list"
    fi
    sort -o "$skipped" "$skipped"
}

# root_copy SRC DEST: copy a root-readable text file of reasonable size; absent files are fine.
root_copy() {
    local src=$1 dest=$2 size
    as_root test -f "$src" || return 0
    size=$(as_root stat -c %s "$src")
    ((size <= MAX_BYTES)) || return 0
    mkdir -p "$(dirname "$dest")"
    as_root cat "$src" >"$dest"
}

# The verbose listing repeats each entry as raw device-path bytes, which embed partition GUIDs.
efi_entries() {
    as_root efibootmgr -v | sed -E '/^[[:space:]]/d; s/(\.[eE][fF][iI])[0-9a-fA-F]+$/\1/; s/[0-9a-fA-F]{20,}$//' | redact
}

gen_boot() {
    local d=$PUB/boot f
    mkdir -p "$d"
    root_copy /etc/default/grub "$d/grub.default"
    root_copy /etc/mkinitcpio.conf "$d/mkinitcpio.conf"
    root_copy /etc/initramfs-tools/initramfs.conf "$d/initramfs-tools/initramfs.conf"
    root_copy /etc/initramfs-tools/modules "$d/initramfs-tools/modules"
    while IFS= read -r f; do
        if etc_noise "$f"; then continue; fi
        root_copy "$f" "$d/mkinitcpio.d/${f##*/}"
    done < <( (as_root find /etc/mkinitcpio.d -maxdepth 1 -type f 2>/dev/null || true) | sort)
    root_copy /boot/grub/grub.cfg "$d/grub.cfg"
    cp /proc/cmdline "$d/cmdline.txt"
    if have efibootmgr; then efi_entries >"$d/efibootmgr.txt" || rm -f "$d/efibootmgr.txt"; fi
    cat >"$d/NOTE.md" <<'EOF'
# Boot files: reference only

These are copies for reading, not for restoring. Never copy them back over a working install
without understanding every line.

- On this machine (NVIDIA RTX 5090) the NVIDIA driver must not be loaded early from the initramfs.
  Adding `nvidia`, `nvidia_modeset`, `nvidia_uvm` or `nvidia_drm` to `MODULES=` in
  `mkinitcpio.conf` (or the initramfs-tools equivalent) hangs boot.
- `grub.cfg` is generated by `grub-mkconfig`; regenerate it instead of copying it.
- `cmdline.txt` and `efibootmgr.txt` describe the current boot; the partition and filesystem
  identifiers differ on a reinstall.
- The installer in this repository never edits the bootloader, kernel command line or initramfs.
EOF
}

# theme_names KIND: sorted names of gtk, icon or cursor themes in the usual directories.
theme_names() {
    local kind=$1 base t
    local -a bases
    case $kind in
    gtk) bases=(/usr/share/themes "$HOME/.local/share/themes" "$HOME/.themes") ;;
    *) bases=(/usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons") ;;
    esac
    for base in "${bases[@]}"; do
        [[ -d $base ]] || continue
        for t in "$base"/*/; do
            [[ -d $t ]] || continue
            case $kind in
            gtk) [[ -d ${t}gtk-3.0 || -d ${t}gtk-4.0 || -d ${t}gtk-2.0 ]] || continue ;;
            cursor) [[ -d ${t}cursors ]] || continue ;;
            icon) [[ -f ${t}index.theme && ! -d ${t}cursors ]] || continue ;;
            esac
            t=${t%/}
            printf '%s\n' "${t##*/}"
        done
    done | sort -u
}

gen_desktop() {
    local d=$PUB/desktop
    mkdir -p "$d"
    if have dconf && dconf dump / >"$WORK/dconf.full" 2>/dev/null; then
        grep -viE '^[^=]*(token|secret|password|passphrase|api-?key|credential)[^=]*=' "$WORK/dconf.full" >"$d/dconf.ini" || true
        if ! cmp -s "$WORK/dconf.full" "$d/dconf.ini"; then
            mkdir -p "$PRIV/desktop"
            cp "$WORK/dconf.full" "$PRIV/desktop/dconf.ini"
            printf 'desktop/dconf.ini\n' >>"$WORK/routed.txt"
        fi
    fi
    if have gsettings; then
        gsettings list-recursively org.gnome.desktop.interface 2>/dev/null | sort >"$d/gsettings-interface.txt" || rm -f "$d/gsettings-interface.txt"
    fi
    if have fc-list; then fc-list : family | sort -u >"$d/fonts.txt"; fi
    {
        printf '## gtk themes\n'
        theme_names gtk
        printf '\n## icon themes\n'
        theme_names icon
        printf '\n## cursor themes\n'
        theme_names cursor
    } >"$d/themes.txt"
}

# Credential files and directories, relative to $HOME; copied to private/home/.
PRIVATE_HOME=(
    .ssh .gnupg .config/zsh/secrets.zsh .claude/settings.json .claude.json .config/gh
    .git-credentials .netrc .docker/config.json .config/rclone .aws .azure .kube/config
    .config/gcloud/credentials.db .config/gcloud/access_tokens.db
    .config/gcloud/application_default_credentials.json .config/gcloud/legacy_credentials
    .config/gdrive3 .config/onedrive/refresh_token .config/github-copilot .config/configstore
)

# Application profiles and data stores directly under ~/.config; never captured.
APP_DIRS=(
    google-chrome google-chrome-for-testing BraveSoftware vivaldi opera microsoft-edge chromium
    chromium-headless Slack 'Code - Insiders' Code Cursor Kiro Antigravity Notion
    notion-app-enhanced notion-electron spotify figma-linux LarkInternational bytertc Claude
    Claude-3p claude ai.opencode.desktop 'Docker Desktop' JetBrains libreoffice teamviewer gcloud
    goa-1.0 utsav nvm sst basic-memory Insync baidunetdisk Bitwarden drata-agent balenaEtcher
    'Android Open Source Project' .android discord vesktop WebCord Element Signal teams-for-linux
    rustdesk anydesk kite-mcp warp-terminal opencode dotman
)

# Directory names that hold caches or generated data wherever they appear (find -iname globs).
CACHE_DIRS=(
    '*cache*' node_modules .git logs log __pycache__ .venv venv 'crash*' 'Local Storage'
    'Session Storage' IndexedDB 'Service Worker' blob_storage databases Partitions telemetry
    extensions versions .omca .claude '*.backup*' '*.bak*'
)

home_transient() {
    case ${1##*/} in
    *.tmp.* | .zcompdump* | *.lock | *lockfile* | *.pid | *.sock | Singleton* | *telemetry*) return 0 ;;
    esac
    return 1
}

home_noise() {
    case ${1##*/} in
    *.log | *.bak | *.bak-* | *.bak.* | *.backup | *.backup.* | *.orig | *.old | *.swp | *.tmp | *~) return 0 ;;
    *.pacnew | *.zwc | *.sqlite | *.sqlite-* | *.sqlite3 | *.db | *.db-* | *-journal | *.so | *.so.* | *.pyc) return 0 ;;
    *_history | .viminfo | .lesshst | .Xauthority | .ICEauthority | .wget-hsts) return 0 ;;
    esac
    return 1
}

# is_under REL PATH...: REL equals, or lies below, one of the paths.
is_under() {
    local rel=$1 p
    shift
    for p in "$@"; do
        if [[ $rel == "$p" || $rel == "$p"/* ]]; then return 0; fi
    done
    return 1
}

# classify REL SIZE: keep, secret, noise, transient or large. Transient files are dropped silently.
classify() {
    if secret_name "$1"; then
        echo secret
    elif home_transient "$1"; then
        echo transient
    elif home_noise "$1"; then
        echo noise
    elif (($2 > MAX_BYTES)); then
        echo large
    else
        echo keep
    fi
}

gen_home_extra() {
    local d=$PUB/home-extra skipped=$PUB/home-extra/SKIPPED.txt
    local manifest=$REPO/manifest/home.list typ size path base reason
    local -a covered=() prune_cov=() prune_dirs=() keep=() secret=()
    mkdir -p "$d"
    : >"$skipped"

    if [[ -r $manifest ]]; then
        mapfile -t covered < <(awk '!/^[[:space:]]*(#|!|$)/ { print $1 }' "$manifest")
    else
        warn "$manifest not found; home-extra will not exclude anything"
    fi
    for path in "${covered[@]}"; do prune_cov+=(-path "$path" -o); done
    for path in "${APP_DIRS[@]}"; do prune_dirs+=(-path ".config/$path" -o); done
    for path in "${PRIVATE_HOME[@]}"; do
        if [[ $path == .config/* ]]; then prune_dirs+=(-path "$path" -o); fi
    done
    for path in "${CACHE_DIRS[@]}"; do prune_dirs+=(-iname "$path" -o); done

    local found=$WORK/home-config.lst rc=0
    (
        cd "$HOME"
        find .config \
            \( "${prune_cov[@]}" -false \) -prune -o \
            \( -type d \( "${prune_dirs[@]}" -false \) -prune -printf 'D\t0\t%p\0' \) -o \
            \( \( -type f -o -type l \) -printf '%y\t%s\t%p\0' \)
    ) >"$found" 2>"$WORK/home-config.err" || rc=$?
    ((rc <= 1)) || die "find failed under ~/.config (exit $rc)"
    sed -n "s|^find: '\(.*\)': Permission denied\$|\1/\tunreadable|p" "$WORK/home-config.err" >>"$skipped"

    while IFS=$'\t' read -r -d '' typ size path; do
        if [[ $typ == D ]]; then
            base=${path#.config/}
            if is_under "$path" "${PRIVATE_HOME[@]}"; then
                reason='credentials (copied to private/)'
            elif [[ $base != */* ]]; then
                reason='application data or profile'
            else
                reason='cache or generated data'
            fi
            printf '%s/\t%s\n' "$path" "$reason" >>"$skipped"
        elif [[ $typ == l ]]; then
            printf '%s\tsymlink -> %s\n' "$path" "$(readlink "$HOME/$path")" >>"$skipped"
        elif is_under "$path" "${PRIVATE_HOME[@]}"; then
            continue
        else
            case $(classify "$path" "$size") in
            keep) keep+=("$path") ;;
            secret) secret+=("$path") ;;
            noise) printf '%s\tnoise (log, backup, lock, history or database)\n' "$path" >>"$skipped" ;;
            large) printf '%s\t>1MB\n' "$path" >>"$skipped" ;;
            *) ;;
            esac
        fi
    done <"$found"

    (cd "$HOME" && find . -maxdepth 1 -name '.*' \( -type f -o -type l \) -printf '%y\t%s\t%p\0') >"$found"
    while IFS=$'\t' read -r -d '' typ size path; do
        path=${path#./}
        if is_under "$path" "${covered[@]}" "${PRIVATE_HOME[@]}"; then continue; fi
        if [[ $typ == l ]]; then
            printf '%s\tsymlink -> %s\n' "$path" "$(readlink "$HOME/$path")" >>"$skipped"
            continue
        fi
        case $(classify "$path" "$size") in
        keep) keep+=("$path") ;;
        secret) secret+=("$path") ;;
        noise) printf '%s\tnoise (log, backup, lock, history or database)\n' "$path" >>"$skipped" ;;
        large) printf '%s\t>1MB\n' "$path" >>"$skipped" ;;
        *) ;;
        esac
    done <"$found"

    if ((${#keep[@]})); then
        printf '%s\0' "${keep[@]}" | tar_copy "$HOME" "$d" user
        printf '%s\0' "${keep[@]}" | drop_binaries "$d" '' "$skipped"
    fi
    if ((${#secret[@]})); then
        printf '%s\0' "${secret[@]}" | tar_copy "$HOME" "$PRIV/home-extra" user
        printf 'home-extra/%s\n' "${secret[@]}" >>"$WORK/routed.txt"
    fi
    sort -o "$skipped" "$skipped"
}

gen_private() {
    local s
    local -a present=()
    mkdir -p "$PRIV"
    for s in "${PRIVATE_HOME[@]}"; do
        if [[ -e $HOME/$s || -L $HOME/$s ]]; then
            present+=("$s")
            printf '%s\n' "\$HOME/$s" >>"$WORK/private-groups.txt"
        fi
    done
    if ((${#present[@]})); then
        (
            cd "$HOME"
            for s in "${present[@]}"; do find "./$s" ! -type s ! -type d -print0; done
        ) | tar_copy "$HOME" "$PRIV/home" user
    fi
    if [[ -s $WORK/etc-private.list ]]; then
        sort -u "$WORK/etc-private.list" | sed 's|^/||' | tr '\n' '\0' | tar_copy / "$PRIV" root
    fi
    sort -u "$WORK/etc-private-groups.txt" >>"$WORK/private-groups.txt"
}

# Move every tracked file the scan flags into private/ at the same relative path.
route_flagged() {
    local rel flagged
    flagged=$(scan_tree "$PUB")
    while IFS= read -r rel; do
        [[ -n $rel ]] || continue
        mkdir -p "$PRIV/$(dirname "$rel")"
        mv "$PUB/$rel" "$PRIV/$rel"
        printf '%s\n' "$rel" >>"$WORK/routed.txt"
    done <<<"$flagged"
}

gen_index() {
    local out=$PUB/etc/INDEX.txt path kind
    {
        printf '# file\tkind (modified:<package> | unowned | curated | private)\n'
        while IFS=$'\t' read -r path kind; do
            if [[ -e $PUB/${path#/} ]]; then
                printf '%s\t%s\n' "$path" "$kind"
            elif grep -qxF "${path#/}" "$WORK/routed.txt"; then
                printf '%s\tprivate\n' "$path"
            fi
        done <"$WORK/etc-index.tsv"
        sort -u "$WORK/etc-private-groups.txt" | awk '{ print $0 "\tprivate" }'
    } | {
        IFS= read -r header
        printf '%s\n' "$header"
        sort -t$'\t' -k1,1 -u
    } >"$out.tmp"
    mv "$out.tmp" "$out"
}

fact_cpu() { lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -n1 || true; }
fact_gpu() {
    local g
    if have nvidia-smi && g=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1) && [[ -n $g ]]; then
        printf '%s' "$g"
    else
        { hw_gpu_lines 2>/dev/null || true; } | head -n1 | sed -E 's/^.*\]: //; s/ \[[0-9a-f]{4}:[0-9a-f]{4}\].*$//'
    fi
}

# Backticks in the printf and sed strings below are Markdown, not command substitution.
# shellcheck disable=SC2016
gen_readme() {
    local out=$PUB/README.md date_str pretty kernel cpu gpu hw
    if [[ -n ${SOURCE_DATE_EPOCH:-} ]]; then date_str=$(date -u -d "@$SOURCE_DATE_EPOCH" +%F); else date_str=$(date +%F); fi
    pretty=$(os_value PRETTY_NAME)
    kernel=$(uname -r)
    cpu=$(fact_cpu)
    gpu=$(fact_gpu)
    hw=$(printf '%s %s' "$(cat /sys/class/dmi/id/board_vendor 2>/dev/null || true)" "$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)")
    {
        printf '# %s\n\n' "$HOST"
        printf 'Configuration snapshot generated by `scripts/snapshot.sh` on %s. Re-run the script to refresh it; do not edit these files by hand.\n\n' "$date_str"
        printf '| | |\n|---|---|\n'
        printf '| Distro | %s |\n| Kernel | %s |\n| Board | %s |\n| CPU | %s |\n| GPU | %s |\n\n' "${pretty:-unknown}" "$kernel" "${hw:-unknown}" "${cpu:-unknown}" "${gpu:-unknown}"
        cat <<'EOF'
## What is here

| Path | Holds |
|---|---|
| `system.txt` | hostnamectl, os-release, kernel command line, timezone, locale, block devices, mounts, swap and zram |
| `hardware.txt` | DMI, CPU, memory, GPU, PCI and USB devices, monitors (identifiers redacted) |
| `packages/` | package lists: `pacman-native.txt`, `pacman-foreign.txt`, `pacman-all.txt` (with versions) or `apt-manual.txt` and `dpkg-all.txt`, plus cargo, npm, bun, uv, pipx, go and flatpak lists when those tools exist |
| `services/` | enabled unit files, enabled timers and masked units, for the system and the user manager |
| `etc/` | modified package config files and files no package owns, paths preserved; `INDEX.txt` says which is which and `SKIPPED.txt` lists binary or oversized files that were not copied |
| `boot/` | reference copies of grub, mkinitcpio and initramfs settings, the kernel command line and EFI entries; read `boot/NOTE.md` first |
| `desktop/` | dconf dump, gsettings interface keys, installed font families, icon, cursor and GTK theme names |
| `home-extra/` | text configs from `~/.config` and top-level dotfiles that `manifest/home.list` does not capture; `SKIPPED.txt` lists what was left out, by directory |

Files under `etc/` are backups for reading. `etc/pacman.conf` is captured as it is on this machine
(it may enable testing and third-party repositories); the installer does not deploy it.
Command reports (`system.txt`, `hardware.txt`, `boot/efibootmgr.txt`) have filesystem UUIDs, MAC
addresses and serial numbers removed. Verbatim config copies (`etc/fstab`, `boot/grub.cfg`,
`boot/cmdline.txt`) keep the identifiers they contain.

## Restore

1. Packages. Either run `./install.sh` with the role and groups that match this machine (see
   `packages/` in the repository root), or install straight from the lists here:
EOF
        case $FAMILY in
        arch) printf '   `sudo pacman -S --needed - < packages/pacman-native.txt`, then `yay -S --needed - < packages/pacman-foreign.txt` for the AUR packages.\n' ;;
        debian) printf '   `xargs -a packages/apt-manual.txt sudo apt-get install -y`.\n' ;;
        *) printf '   Use the lists in `packages/` as a reference for your package manager.\n' ;;
        esac
        cat <<'EOF'
2. User configs: `bin/dotfiles deploy` copies `home/` into `$HOME`. Copy anything you want back
   from `home-extra/` by hand.
3. `/etc` files: copy by hand, one at a time, after reading the diff against the new system
   (`etc/INDEX.txt` lists each file and why it is there). Do not restore `etc/pacman.conf` or
   `etc/fstab` blindly.
4. Boot files: reference only, see `boot/NOTE.md`.
5. Services: `systemctl enable` the units listed in `services/enabled.txt` (use `--user` for the
   user section).
6. Secrets: restore from `private/machines/<hostname>/` (git-ignored, kept outside version
   control). Keep directories at mode 0700 and files at 0600.

## Moved to private/

Paths only. Contents are never written to this tree.

Always private by design:

EOF
        sort -u "$WORK/private-groups.txt" | sed 's/^/- `/; s/$/`/'
        printf '\nRouted by file name or by the secret scan (relative to this directory). `desktop/dconf.ini` stays in this tree without its token-like keys; the full dump is in private/.\n\n'
        if [[ -s $WORK/routed.txt ]]; then
            sort -u "$WORK/routed.txt" | sed 's/^/- `/; s/$/`/'
        else
            printf -- '- none\n'
        fi
    } >"$out"
}

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

preflight() {
    local c
    ((EUID != 0)) || die "run as your normal user; the script uses sudo -n for root-only files"
    [[ $HOST =~ ^[A-Za-z0-9._-]+$ ]] || die "unusable hostname '$HOST'"
    have sudo || die "sudo not found"
    sudo -n true 2>/dev/null || die "passwordless sudo is required (sudo -n true failed)"
    for c in find tar sort awk sed grep mktemp; do have "$c" || die "missing required tool: $c"; done
    case " $(os_value ID) $(os_value ID_LIKE) " in
    *" arch "*) FAMILY=arch ;;
    *" debian "* | *" ubuntu "*) FAMILY=debian ;;
    esac
    if have git && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
        git -C "$REPO" check-ignore -q private/machines/probe ||
            die "private/ is not git-ignored; refusing to write secrets into the repository"
    fi
}

main() {
    local hits leaks
    case ${1:-} in
    -h | --help)
        usage
        return 0
        ;;
    --scan)
        [[ -d ${2:-} ]] || die "usage: $0 --scan DIR"
        scan_selftest
        hits=$(scan_tree "$2")
        if [[ -n $hits ]]; then
            printf '%s\n' "$hits"
            return 1
        fi
        printf 'clean: no secret patterns in %s\n' "$2"
        return 0
        ;;
    '') ;;
    *) die "unknown argument '$1' (try --help)" ;;
    esac

    preflight
    scan_selftest

    mkdir -p "$REPO/private"
    chmod 700 "$REPO/private"
    STAGE=$(mktemp -d "$REPO/private/.staging.XXXXXX")
    PUB=$STAGE/pub
    PRIV=$STAGE/priv
    WORK=$STAGE/work
    mkdir -p "$PUB" "$PRIV" "$WORK"
    : >"$WORK/routed.txt"
    : >"$WORK/private-groups.txt"

    log "snapshotting $HOST ($(os_value PRETTY_NAME), family: $FAMILY)"
    gen_system
    gen_hardware
    gen_packages
    gen_services
    gen_etc
    gen_boot
    gen_desktop
    gen_home_extra
    gen_private
    route_flagged
    gen_index
    gen_readme

    chmod -R u=rwX,go=rX "$PUB"
    find "$PRIV" -type d -exec chmod 700 {} +
    find "$PRIV" -type f -exec chmod 600 {} +

    leaks=$(scan_tree "$PUB")
    [[ -z $leaks ]] || die "secret scan flagged the finished snapshot, nothing was written: $(tr '\n' ' ' <<<"$leaks")"

    mkdir -p "$REPO/machines"
    chmod 755 "$REPO/machines"
    swap_in "$PUB" "$REPO/machines/$HOST"
    swap_in "$PRIV" "$REPO/private/machines/$HOST"
    chmod 700 "$REPO/private/machines"
    log "wrote machines/$HOST and private/machines/$HOST"
    log "sizes: tracked $(du -sh "$REPO/machines/$HOST" | cut -f1), private $(du -sh "$REPO/private/machines/$HOST" | cut -f1)"
}

main "$@"
