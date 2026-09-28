#!/bin/sh
# vibe-safe secret scan. Two modes:
#   secret-scan.sh --staged   what is about to be committed (the pre-commit hook)
#   secret-scan.sh --tree     every tracked file (the CI gate)
# Exit 0 clean, exit 1 when something key-shaped or a secret file is found.
# If gitleaks is installed it is used instead of the patterns below: it is better.
# Zero dependencies otherwise: POSIX sh, git, grep.
set -u
mode="${1:---staged}"

if command -v gitleaks >/dev/null 2>&1; then
  case "$mode" in
    --staged) gitleaks protect --staged --no-banner --redact ;;
    --tree)   gitleaks detect --no-banner --redact ;;
    *) echo "usage: secret-scan.sh --staged|--tree" >&2; exit 2 ;;
  esac
  exit $?
fi

# Files that are secrets by their name alone. .env.example and friends are allowed:
# they hold names, not values.
secret_paths='(^|/)\.env([.-](?!example|sample|template|dist)[A-Za-z0-9._-]+)?$|\.pem$|\.p12$|\.pfx$|\.key$|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|(^|/)\.npmrc$|(^|/)\.pypirc$|(^|/)service-account.*\.json$|(^|/)credentials\.json$'

# Strings shaped like keys. Prefixes are the providers' own; the generic ones need a
# value of real length so a placeholder like KEY=xxx passes.
secret_values='AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|sk_(live|test)_[A-Za-z0-9]{16,}|rk_live_[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|(postgres|postgresql|mysql|mongodb(\+srv)?|redis|amqp)://[^:/@\s]+:[^@\s]{4,}@|(?i:api[_-]?key|secret|token|password|passwd|credential)["'"'"']?\s*[:=]\s*["'"'"'][A-Za-z0-9/+_=.-]{16,}["'"'"']'

case "$mode" in
  --staged)
    files=$(git diff --cached --name-only --diff-filter=ACMR)
    content() { git diff --cached -U0 --diff-filter=ACMR -- "$1" | grep '^+' | grep -v '^+++'; }
    ;;
  --tree)
    files=$(git ls-files)
    content() { cat "$1"; }
    ;;
  *) echo "usage: secret-scan.sh --staged|--tree" >&2; exit 2 ;;
esac

status=0
for f in $files; do
  if printf '%s\n' "$f" | grep -qP "$secret_paths"; then
    echo "secret-scan: $f is a secret file by its name; it must not be committed" >&2
    status=1
    continue
  fi
  case "$f" in *.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.woff|*.woff2|*.lock|package-lock.json|pnpm-lock.yaml) continue ;; esac
  hits=$(content "$f" 2>/dev/null | grep -nP "$secret_values" | grep -v 'secret-scan:allow' | cut -c1-40)
  if [ -n "$hits" ]; then
    echo "secret-scan: $f holds something shaped like a key (line shown, value cut):" >&2
    printf '%s\n' "$hits" | sed 's/^/    /' >&2
    status=1
  fi
done

if [ $status -ne 0 ]; then
  cat >&2 <<'MSG'

secret-scan: stopped. A key in a committed file is in the repository's history for good,
and deleting the line later does not undo it. Put the value in the platform's settings or
a local .env that is git-ignored; keep only the NAME in the repo (.env.example).
If this is a false alarm (a test string, an example), add the comment "secret-scan:allow"
on that line, or bypass once with ANF_ALLOW_SECRET=1 (the bypass is written to
vibe-safe/bypass.log so it is visible later).
MSG
fi
exit $status
