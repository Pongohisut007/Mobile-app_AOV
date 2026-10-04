#!/usr/bin/env bash
set -euo pipefail

: "${GIT_USERNAME:?GIT_USERNAME is required}"
: "${GIT_TOKEN:?GIT_TOKEN is required}"
: "${GITOPS_BRANCH:?GITOPS_BRANCH is required}"

# Keep credentials in the binding environment instead of persisting them in
# the remote URL. The temporary helper contains variable names, not secrets.
askpass_file="$(mktemp)"
trap 'rm -f "$askpass_file"' EXIT
cat > "$askpass_file" <<'ASKPASS'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' "$GIT_USERNAME" ;;
  *Password*) printf '%s\n' "$GIT_TOKEN" ;;
esac
ASKPASS
chmod 700 "$askpass_file"
export GIT_ASKPASS="$askpass_file"
export GIT_TERMINAL_PROMPT=0

git fetch origin "$GITOPS_BRANCH"
if ! git rebase "origin/$GITOPS_BRANCH"; then
  git rebase --abort
  exit 1
fi
git push origin "HEAD:$GITOPS_BRANCH"
