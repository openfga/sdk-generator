#!/usr/bin/env bash
# Extracted from .github/workflows/release-please.yml so the parsing logic can
# be unit-tested independently of GitHub Actions.
#
# This generator produces single-package SDKs (one package per repository),
# so the release-please manifest uses the root component key ".". The helper
# still supports prefixed component keys (e.g. "pkg/go") so the same script and
# tests can be reused for monorepo-style manifests.
#
# Usage:
#   parse-release.sh manifest-diff <current.json> <previous.json>
#     → prints JSON array of {component, version, tag_name} for changed pkgs
#       exits 1 if no changes detected
#       The root component "." maps to a plain "v<version>" tag, while any
#       other component maps to "<component>/v<version>".
#
#   parse-release.sh changelog-notes <changelog-path> <version>
#     → prints the release notes section for the given version
#       falls back to "Release <version>" if no section found
set -euo pipefail

cmd="${1:-}"
shift || true

case "$cmd" in
  manifest-diff)
    current_file="$1"
    previous_file="$2"

    releases=$(jq -c -n \
      --argjson cur  "$(cat "$current_file")" \
      --argjson prev "$(cat "$previous_file")" \
      '[ $cur | to_entries[]
         | select(.value != $prev[.key])
         | { component: .key,
             version:   .value,
             tag_name:  (if .key == "." then "v\(.value)" else "\(.key)/v\(.value)" end) } ]')

    if [[ $(jq 'length' <<<"$releases") -eq 0 ]]; then
      echo "::error::No version changes detected." >&2
      exit 1
    fi

    echo "$releases"
    ;;

  changelog-notes)
    changelog="$1"
    version="$2"

    notes=$(awk -v ver="$version" '
      BEGIN {
        gsub(/\./, "\\.", ver)
        pattern = "(^|[^0-9A-Za-z.-])" ver "([^0-9A-Za-z.-]|$)"
      }
      /^## / {
        if (found) exit
        if ($0 ~ pattern) { found=1; next }
      }
      found { print }
    ' "$changelog")

    if [[ -z "$notes" ]]; then
      echo "Release ${version}"
    else
      echo "$notes"
    fi
    ;;

  *)
    echo "Usage: $0 {manifest-diff|changelog-notes} ..." >&2
    exit 2
    ;;
esac

