#!/usr/bin/env bash
# Encrypted backup of the secrets that scripts/snapshot.sh keeps in the git-ignored private/.
#
#   secrets.sh backup  [--host NAME]          private/machines/NAME -> secrets/NAME.tar.age
#   secrets.sh restore [--host NAME] [--system] [--dry-run] [--yes]
#                                             put the secrets back in place
#   secrets.sh extract [--host NAME] DIR      decrypt everything into DIR, for what restore skips
#
# The archive is encrypted with age and a passphrase (scrypt), so it can be committed to this
# public repo: it is exactly as safe as the passphrase. Use six or more random words and keep
# them in a password manager. NAME defaults to this machine's hostname; restore and extract fall
# back to the only archive in secrets/.
#
# restore puts back everything that belongs under $HOME (SSH and GPG keys, tokens, app logins)
# with owner-only permissions, saving any file it replaces. --system also restores the Wi-Fi
# profiles and SSH host keys, with sudo. Password hashes (/etc/shadow) and /etc files whose
# original permissions were not recorded are never restored automatically: extract them and
# copy what you need by hand.
set -Eeuo pipefail

REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
PRIVATE=$REPO/private/machines
VAULT=$REPO/secrets
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
AGE_HEADER='-----BEGIN AGE ENCRYPTED FILE-----'
# Snapshot leftovers not worth restoring: regenerated at runtime, or stale local backups.
SKIP_HOME=('.zshenv.bak-*' '.pulse-cookie' '.config/pulse/*cookie' '*/master-key.aes')

# Temporary file or directory to remove on exit (a global: the trap runs after functions return).
WORK=''
trap '[[ -z $WORK ]] || rm -rf -- "$WORK"' EXIT

die() { printf 'secrets: %s\n' "$*" >&2; exit 1; }
info() { printf 'secrets: %s\n' "$*"; }

usage() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

need_age() {
  command -v age >/dev/null || die "age is not installed (it is in the base package list; run ./install.sh)"
  [[ -r /dev/tty ]] || die "age asks for the passphrase on a terminal; run this from one"
}

# host_for MODE NAME: the host to act on.
host_for() {
  local mode=$1 name=$2
  if [[ -n $name ]]; then
    echo "$name"
    return
  fi
  if [[ $mode == backup || -e $VAULT/$(uname -n).tar.age ]]; then
    uname -n
    return
  fi
  local -a found=("$VAULT"/*.tar.age)
  [[ -e ${found[0]} ]] || die "no archives in $VAULT"
  ((${#found[@]} == 1)) || die "several archives in $VAULT; choose one with --host"
  basename "${found[0]}" .tar.age
}

cmd_backup() {
  local host=$1 out
  [[ -d $PRIVATE/$host ]] || die "$PRIVATE/$host is missing; run bin/dotfiles snapshot first"
  need_age
  mkdir -p "$VAULT"
  out=$VAULT/$host.tar.age
  WORK=$(mktemp "$VAULT/.$host.XXXXXX")
  info "encrypting $PRIVATE/$host (snapshot of $(date -r "$PRIVATE/$host" '+%F %R'))"
  info "choose a strong passphrase: six or more random words; age asks for it twice"
  tar -C "$PRIVATE" --owner=0 --group=0 --numeric-owner -czf - "$host" | age --encrypt --passphrase --armor -o "$WORK"
  [[ $(head -n 1 "$WORK") == "$AGE_HEADER" ]] || die "age wrote an unexpected file; $out left unchanged"
  mv -f "$WORK" "$out"
  WORK=''
  info "wrote ${out#"$REPO"/} ($(du -h "$out" | cut -f1)). Commit it:"
  info "  git -C $REPO add secrets/$host.tar.age && git -C $REPO commit -m 'secrets: Update $host'"
}

# decrypt HOST DIR: unpack HOST's archive into DIR (age asks for the passphrase).
decrypt() {
  local host=$1 dir=$2 file=$VAULT/$1.tar.age
  [[ -f $file ]] || die "no archive at $file"
  need_age
  age --decrypt "$file" | tar -C "$dir" -xzf - --no-same-owner
  [[ -d $dir/$host ]] || die "$file does not hold $host/"
}

# mkdir_private DIR: create DIR and any missing parents as owner-only directories.
mkdir_private() {
  local dir=$1
  [[ -d $dir ]] && return 0
  mkdir_private "$(dirname "$dir")"
  mkdir -m 700 "$dir"
}

skip_home() {
  local rel=$1 pat
  for pat in "${SKIP_HOME[@]}"; do
    # shellcheck disable=SC2053  # the patterns are globs on purpose
    [[ $rel == $pat ]] && return 0
  done
  return 1
}

cmd_restore() {
  local host=$1 system=$2 dry=$3 yes=$4 src f rel dest reply backup
  WORK=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/dotfiles-secrets.XXXXXX")
  chmod 700 "$WORK"
  decrypt "$host" "$WORK"
  src=$WORK/$host

  local -a srcs=() rels=() actions=()
  while IFS= read -r -d '' f; do
    rel=${f#"$src"/}
    rel=${rel#*/}
    skip_home "$rel" && continue
    dest=$HOME/$rel
    if [[ -e $dest ]] && cmp -s "$f" "$dest"; then
      continue
    fi
    srcs+=("$f")
    rels+=("$rel")
    if [[ -e $dest ]]; then actions+=(replace); else actions+=(add); fi
  done < <(find "$src/home" "$src/home-extra" -type f -print0 2>/dev/null | sort -z)

  local i
  if ((${#rels[@]})); then
    echo "Under \$HOME:"
    for i in "${!rels[@]}"; do printf '  %-8s ~/%s\n' "${actions[$i]}" "${rels[$i]}"; done
  else
    echo "Under \$HOME: everything already matches the backup"
  fi
  local -a nm=() hostkeys=() manual=()
  while IFS= read -r -d '' f; do
    rel=${f#"$src"/}
    case $rel in
      etc/NetworkManager/system-connections/*) nm+=("$f") ;;
      etc/ssh/ssh_host_*) hostkeys+=("$f") ;;
      *) manual+=("/$rel") ;;
    esac
  done < <(find "$src/etc" -type f -print0 2>/dev/null | sort -z)
  if ((system)); then
    echo "System (--system, with sudo): ${#nm[@]} Wi-Fi profile(s), ${#hostkeys[@]} SSH host key file(s)"
  elif ((${#nm[@]} + ${#hostkeys[@]})); then
    echo "Not restoring ${#nm[@]} Wi-Fi profile(s) and ${#hostkeys[@]} SSH host key file(s); add --system for them"
  fi
  if ((${#manual[@]})); then
    echo "Never restored automatically (use 'extract' and copy by hand if you need them):"
    printf '  %s\n' "${manual[@]}"
  fi
  [[ -e $src/desktop/dconf.ini ]] && echo "Desktop settings: 'extract', then: dconf load / < <dir>/$host/desktop/dconf.ini"

  if ((dry)); then
    info "dry run: nothing written"
    return 0
  fi
  if ((!yes)); then
    read -r -p "Restore these now? Replaced files are saved first. [y/N] " reply </dev/tty
    [[ $reply == [yY]* ]] || die "cancelled"
  fi

  backup=$STATE/backups/$(date +%Y%m%d-%H%M%S)-secrets
  for i in "${!rels[@]}"; do
    dest=$HOME/${rels[$i]}
    if [[ -e $dest ]]; then
      mkdir_private "$(dirname "$backup/${rels[$i]}")"
      cp -p "$dest" "$backup/${rels[$i]}"
    fi
    mkdir_private "$(dirname "$dest")"
    install -m 600 "${srcs[$i]}" "$dest"
  done
  # ssh and gpg refuse keys in directories others can read.
  for f in "$HOME/.ssh" "$HOME/.gnupg"; do [[ -d $f ]] && chmod 700 "$f"; done
  if printf '%s\n' "${rels[@]}" | grep -q '^\.gnupg/'; then
    gpgconf --kill gpg-agent 2>/dev/null || true
  fi
  if [[ -d $backup ]]; then
    info "restored ${#rels[@]} file(s) under \$HOME; replaced files are saved in $backup"
  else
    info "restored ${#rels[@]} file(s) under \$HOME"
  fi

  ((system)) || return 0
  local dir
  if ((${#nm[@]})); then
    dir=/etc/NetworkManager/system-connections
    sudo install -d -m 700 -o root -g root "$dir"
    for f in "${nm[@]}"; do sudo install -m 600 -o root -g root "$f" "$dir/${f##*/}"; done
    if command -v nmcli >/dev/null && nmcli -t general status >/dev/null 2>&1; then
      sudo nmcli connection reload
    fi
    info "restored ${#nm[@]} Wi-Fi profile(s)"
  fi
  if ((${#hostkeys[@]})) && [[ ! -d /etc/ssh ]]; then
    info "no /etc/ssh (OpenSSH is not installed): SSH host keys not restored"
  elif ((${#hostkeys[@]})); then
    for f in "${hostkeys[@]}"; do
      dest=/etc/ssh/${f##*/}
      if sudo test -e "$dest"; then
        mkdir_private "$backup/etc/ssh"
        # Read as root, written as the user: the saved copy belongs in the user's backup dir.
        # shellcheck disable=SC2024
        sudo cat "$dest" >"$backup/etc/ssh/${f##*/}"
      fi
      if [[ $f == *.pub ]]; then
        sudo install -m 644 -o root -g root "$f" "$dest"
      else
        sudo install -m 600 -o root -g root "$f" "$dest"
      fi
    done
    info "restored the SSH host keys; restart sshd to use them"
  fi
}

cmd_extract() {
  local host=$1 dir=$2
  [[ -n $dir ]] || die "extract needs a directory"
  mkdir_private "$dir"
  decrypt "$host" "$dir"
  info "decrypted into $dir/$host (owner-only); delete it when you are done"
}

main() {
  local cmd=${1:-}
  [[ -n $cmd ]] || { usage; exit 1; }
  shift
  local name='' system=0 dry=0 yes=0 dir=''
  while (($#)); do
    case $1 in
      --host) name=${2:?--host needs a name}; shift ;;
      --system) system=1 ;;
      --dry-run) dry=1 ;;
      --yes | -y) yes=1 ;;
      -h | --help) usage; exit 0 ;;
      -*) die "unknown option $1" ;;
      *) [[ $cmd == extract && -z $dir ]] || die "unexpected argument $1"; dir=$1 ;;
    esac
    shift
  done
  case $cmd in
    backup) cmd_backup "$(host_for backup "$name")" ;;
    restore) cmd_restore "$(host_for restore "$name")" "$system" "$dry" "$yes" ;;
    extract) cmd_extract "$(host_for extract "$name")" "$dir" ;;
    -h | --help | help) usage ;;
    *) die "unknown command '$cmd' (backup, restore, extract)" ;;
  esac
}

main "$@"
