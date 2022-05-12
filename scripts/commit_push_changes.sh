#!/usr/bin/env bash

cd "${SDK_PATH:?}" || exit

# 0. Check for changes, exit if non found
echo "Step 00. checking for changed files"
# shellcheck disable=SC2091
if $(git status | grep -q "nothing to commit"); then
  echo "CLEAN: no changes found"
  exit 0
fi

echo "DIRTY: changes found"
git status
git diff

# 1. If dry run is enabled, log a message and exit
echo "Step 01. checking for dry run"
if [ -n "$DRY_RUN" ]; then
  echo "DIRTY: dry run is enabled, not committing changes"
  exit 0
fi

# 2. commit
echo "Step 02. committing changed files"
git add .
git commit -m 'build: update with latest changes'

# 3. push
echo "Step 03. pushing changes"
eval "$(ssh-agent -s)"
tmpdir=$(mktemp -d)

echo "${KNOWN_HOSTS}" > "${tmpdir:?}/known_hosts"

ssh-add - <<< "${SSH_KEY}"; GIT_SSH_COMMAND="ssh -vvv -o UserKnownHostsFile=$tmpdir/known_hosts" git push

# 4. If tagging & publishing the sdk is not enabled, exit
echo "Step 04. checking if tagging is disabled"
if [ -n "$TAGGING_DISABLE" ]; then
  echo "Tagging is disabled - skipping"
  exit 0
fi

# 5. Check if the current version of the SDK has been tagged and released, if not tag and push
echo "Step 05. checking if version has been released"
version=$(cat VERSION.txt)
response_code=$(curl -I "https://github.com/${GITHUB_ORG_ID}/${GITHUB_REPO_ID}/releases/tag/v${version}" -o /dev/null -s -w "%{http_code}\n")

echo "response_code $response_code, version $version"

if [[ "$response_code" == "200" ]]; then
  echo "Version code already published - skipping"
  exit 0
fi

# 6. If necessary publish to package manager - e.g. npm or maven, run the publish command
echo "Step 06. publishing"
if [ -n "$PUBLISH_CMD" ]; then
  echo "Publishing command not found - skipping"
  exit 0
fi

echo "Publishing package"
# shellcheck disable=SC2091
$(PUBLISH_CMD)

exit 0
