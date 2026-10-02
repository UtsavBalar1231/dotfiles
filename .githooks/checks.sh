# shellcheck shell=bash
# Checks shared by the pre-commit and pre-push hooks. The repo has a public remote.

SECRET_PATTERN='-----BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[abpr]-[A-Za-z0-9-]{10,}|sk-(ant-)?[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{30,}'
AGE_HEADER='-----BEGIN AGE ENCRYPTED FILE-----'
# The age archives are ciphertext; scanning them for token patterns only finds noise.
# shellcheck disable=SC2034  # used by the hooks that source this file
NOT_ARCHIVES=(. ':(exclude)secrets/*.tar.age')

# check_paths HOOK PATHS REV: refuse anything under private/, and anything under secrets/ that is not
# an armored age archive. REV prefixes paths for `git show` (":" = index, "<commit>:" = a commit).
check_paths() {
  local hook=$1 paths=$2 rev=$3 p bad=0
  if grep -q '^private/' <<<"$paths"; then
    echo "$hook: refusing files under private/ (unencrypted secrets live there)" >&2
    bad=1
  fi
  while IFS= read -r p; do
    [[ $p == secrets/* ]] || continue
    if [[ $p != secrets/*.tar.age || $(git show "$rev$p" | head -n 1) != "$AGE_HEADER" ]]; then
      echo "$hook: $p is not an age-encrypted archive; only 'bin/dotfiles secrets backup' output belongs in secrets/" >&2
      bad=1
    fi
  done <<<"$paths"
  return $bad
}

# count_secret_lines: number of added lines in a patch (stdin) that look like a key or token.
count_secret_lines() {
  # -a: a binary-looking file must not make grep stop printing lines and skip the scan.
  grep -a -E '^\+' | grep -a -E -c -e "$SECRET_PATTERN" || true
}
