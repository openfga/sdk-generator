#!/usr/bin/env bash
if [ -z "$GPG_SECRET_KEY" ]; then
  echo "GPG Key not found - skipping"
  exit 0
fi

echo "Importing GPG Key"
echo -n "$GPG_SECRET_KEY" | base64 --decode | gpg --import
