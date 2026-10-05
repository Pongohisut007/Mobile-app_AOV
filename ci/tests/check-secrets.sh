#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ci/tests/check-secrets.sh [path-to-gitleaks]
scanner="${1:-gitleaks}"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/backend" "$fixture/frontend"
printf '[extend]\nuseDefault = true\n' > "$fixture/default.toml"
example='https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456'
# Generate only synthetic values; never use a real credential in these fixtures.
fake_pat="ghp_$(node -e 'process.stdout.write(require("crypto").randomBytes(18).toString("hex"))')"
fake_key="$(node -e 'process.stdout.write(require("crypto").randomBytes(24).toString("hex"))')"
cd "$fixture"

scan() {
    local expected="$1" config="$2" label="$3" status=0
    "$scanner" dir . --config "$config" --redact --no-banner \
        --report-format json --report-path "$fixture/report.json" \
        > "$fixture/scan.log" 2>&1 || status=$?
    if [[ "$status" != "$expected" ]]; then
        printf 'FAIL: %s (expected exit %s, got %s)\n' "$label" "$expected" "$status" >&2
        exit 1
    fi
    printf 'PASS: %s\n' "$label"
}

printf '%s\n' "$example" > backend/README.md
scan 1 "$fixture/default.toml" 'default rules detect the example'
scan 0 "$repo_root/.gitleaks.toml" 'exact README example is allowed'

printf "api_key = '%s'\n" "$fake_pat" > backend/README.md
scan 1 "$fixture/default.toml" 'default rules detect synthetic GitHub token'
scan 1 "$repo_root/.gitleaks.toml" 'GitHub token in README is blocked'

printf "api_key = '%s'\n" "$fake_key" > backend/README.md
scan 1 "$fixture/default.toml" 'default rules detect synthetic generic key'
scan 1 "$repo_root/.gitleaks.toml" 'generic key in README is blocked'

printf "%s\napi_key = '%s'\n" "$example" "$fake_key" > backend/README.md
scan 1 "$repo_root/.gitleaks.toml" 'example does not hide another secret in README'

printf '%s\n' "$example" > backend/README.md
printf '%s\n' "$example" > frontend/README.md
scan 1 "$repo_root/.gitleaks.toml" 'example in another file is not exempt'
