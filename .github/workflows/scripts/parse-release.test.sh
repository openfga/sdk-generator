#!/usr/bin/env bash
# Tests for parse-release.sh
# Run: bash .github/workflows/scripts/parse-release.test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSE="$SCRIPT_DIR/parse-release.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  ✅ $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name"
    echo "     expected: $expected"
    echo "     actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  ✅ $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name"
    echo "     expected to contain: $needle"
    echo "     actual:              $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" -eq "$actual" ]]; then
    echo "  ✅ $name (exit=$actual)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name"
    echo "     expected exit: $expected"
    echo "     actual exit:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# helper
diff_run() {
  echo "$1" >"$TMP/cur.json"
  echo "$2" >"$TMP/prev.json"
  "$PARSE" manifest-diff "$TMP/cur.json" "$TMP/prev.json" 2>/dev/null
}

#####################################################################
# manifest-diff — single-package SDKs (root component ".")
#####################################################################
echo
echo "=== manifest-diff (single-package, root \".\") ==="

# 1. Root package bumped → plain "v<version>" tag
out=$(diff_run '{".":"0.10.2"}' '{".":"0.10.1"}')
assert_eq "root package bump produces v-prefixed tag" \
  '[{"component":".","version":"0.10.2","tag_name":"v0.10.2"}]' \
  "$out"

# 2. Root pre-release bump
out=$(diff_run '{".":"1.0.0-beta.1"}' '{".":"1.0.0-beta.0"}')
assert_eq "root pre-release bump" \
  '[{"component":".","version":"1.0.0-beta.1","tag_name":"v1.0.0-beta.1"}]' \
  "$out"

# 3. Root pre-release → stable
out=$(diff_run '{".":"1.0.0"}' '{".":"1.0.0-rc.1"}')
assert_eq "root pre-release to stable" \
  '[{"component":".","version":"1.0.0","tag_name":"v1.0.0"}]' \
  "$out"

# 4. Substring collision (0.2.4 → 0.2.40)
out=$(diff_run '{".":"0.2.40"}' '{".":"0.2.4"}')
assert_eq "root 0.2.4 → 0.2.40 detected as change" \
  '[{"component":".","version":"0.2.40","tag_name":"v0.2.40"}]' \
  "$out"

# 5. No change → exit 1
echo '{".":"0.10.1"}' >"$TMP/cur.json"
cp "$TMP/cur.json" "$TMP/prev.json"
err=$("$PARSE" manifest-diff "$TMP/cur.json" "$TMP/prev.json" 2>&1 >/dev/null)
code=$?
assert_exit_code "no changes exits non-zero" 1 "$code"
assert_contains "no changes error message" "No version changes detected" "$err"

#####################################################################
# manifest-diff — monorepo-style component keys (forward-compatible)
#####################################################################
echo
echo "=== manifest-diff (prefixed components) ==="

# 6. Only one component bumped
out=$(diff_run \
  '{"pkg/go":"0.3.0","pkg/js":"0.2.4"}' \
  '{"pkg/go":"0.2.2","pkg/js":"0.2.4"}')
assert_eq "only pkg/go bumped" \
  '[{"component":"pkg/go","version":"0.3.0","tag_name":"pkg/go/v0.3.0"}]' \
  "$out"

# 7. Two components bumped together
out=$(diff_run \
  '{"pkg/go":"0.3.0","pkg/js":"0.2.5"}' \
  '{"pkg/go":"0.2.2","pkg/js":"0.2.4"}')
assert_eq "pkg/go + pkg/js bumped together" \
  '[{"component":"pkg/go","version":"0.3.0","tag_name":"pkg/go/v0.3.0"},{"component":"pkg/js","version":"0.2.5","tag_name":"pkg/js/v0.2.5"}]' \
  "$out"

# 8. New component added
out=$(diff_run \
  '{"pkg/go":"0.2.2","pkg/rust":"0.1.0"}' \
  '{"pkg/go":"0.2.2"}')
assert_eq "new component added to manifest" \
  '[{"component":"pkg/rust","version":"0.1.0","tag_name":"pkg/rust/v0.1.0"}]' \
  "$out"

# 9. Removed component does not trigger a release
echo '{"pkg/go":"0.2.2"}' >"$TMP/cur.json"
echo '{"pkg/go":"0.2.2","pkg/js":"0.2.4"}' >"$TMP/prev.json"
"$PARSE" manifest-diff "$TMP/cur.json" "$TMP/prev.json" >/dev/null 2>&1
code=$?
assert_exit_code "removed component does not trigger release" 1 "$code"

#####################################################################
# changelog-notes tests
#####################################################################
echo
echo "=== changelog-notes ==="

# Build a representative changelog
cat >"$TMP/CHANGELOG.md" <<'EOF'
# Changelog

## Unreleased

## [0.2.40](https://github.com/foo/bar/compare/v0.2.39...v0.2.40) (2026-06-01)


### Added

* feature for 0.2.40 ([#999](https://github.com/foo/bar/issues/999))


## [0.2.4](https://github.com/foo/bar/compare/v0.2.3...v0.2.4) (2026-05-28)

> [!NOTE]
> Manual note added between version headings.

### Fixed

* bug fix for 0.2.4 ([#283](https://github.com/foo/bar/issues/283))


## [0.2.3](https://github.com/foo/bar/compare/v0.2.2...v0.2.3) (2026-05-26)


### Miscellaneous

* release 0.2.3


## [0.2.0-beta.1](https://github.com/foo/bar/compare/v0.2.0-beta.0...v0.2.0-beta.1) (2026-04-10)


### Added

* beta feature
EOF

# 1. Latest version captures its own section + ### subheadings
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "0.2.40")
assert_contains "0.2.40 captures ### Added subheading" "### Added" "$out"
assert_contains "0.2.40 captures its body" "feature for 0.2.40" "$out"
[[ "$out" != *"0.2.4 "* && "$out" != *"v0.2.4)"* ]] \
  && { echo "  ✅ 0.2.40 does not leak into 0.2.4 section"; PASS=$((PASS+1)); } \
  || { echo "  ❌ 0.2.40 leaked into 0.2.4 section: $out"; FAIL=$((FAIL+1)); }

# 2. Substring collision: 0.2.4 should NOT capture 0.2.40
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "0.2.4")
assert_contains "0.2.4 captures manual NOTE block" "Manual note added" "$out"
assert_contains "0.2.4 captures ### Fixed" "### Fixed" "$out"
assert_contains "0.2.4 captures bug fix line" "bug fix for 0.2.4" "$out"
if [[ "$out" == *"feature for 0.2.40"* ]]; then
  echo "  ❌ 0.2.4 incorrectly captured 0.2.40 content"
  FAIL=$((FAIL+1))
else
  echo "  ✅ 0.2.4 does NOT capture 0.2.40 content"
  PASS=$((PASS+1))
fi

# 3. Older version
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "0.2.3")
assert_contains "0.2.3 captures Miscellaneous section" "release 0.2.3" "$out"

# 4. Pre-release version
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "0.2.0-beta.1")
assert_contains "pre-release 0.2.0-beta.1 captured" "beta feature" "$out"

# 5. Compare URL must not falsely match.
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "0.2.39")
assert_eq "URL-only version falls back to default" "Release 0.2.39" "$out"

# 6. Missing version → fallback
out=$("$PARSE" changelog-notes "$TMP/CHANGELOG.md" "9.9.9")
assert_eq "missing version falls back" "Release 9.9.9" "$out"

# 7. GitHub markdown alerts must be preserved verbatim.
cat >"$TMP/ALERTS.md" <<'EOF'
# Changelog

## [1.0.0](https://github.com/foo/bar/compare/v0.9.0...v1.0.0) (2026-07-01)

> [!WARNING]
> Breaking change: API endpoint renamed.

> [!IMPORTANT]
> You must run migrations before upgrading.

> [!TIP]
> See the migration guide for details.

> [!CAUTION]
> Do not skip the manual step in section 4.

> [!NOTE]
> This release was tested on Linux, macOS, and Windows.

### Added

* new shiny feature

## [0.9.0](https://github.com/foo/bar/compare/v0.8.0...v0.9.0) (2026-06-15)

prior content
EOF

out=$("$PARSE" changelog-notes "$TMP/ALERTS.md" "1.0.0")
for kind in WARNING IMPORTANT TIP CAUTION NOTE; do
  assert_contains "alert [!${kind}] preserved" "[!${kind}]" "$out"
done
assert_contains "alert body line preserved" "Breaking change: API endpoint renamed." "$out"
assert_contains "trailing section after alerts preserved" "new shiny feature" "$out"
if [[ "$out" == *"prior content"* ]]; then
  echo "  ❌ capture leaked into 0.9.0 section"
  FAIL=$((FAIL + 1))
else
  echo "  ✅ capture stops cleanly at next version heading"
  PASS=$((PASS + 1))
fi

#####################################################################
# summary
#####################################################################
echo
echo "================================"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

