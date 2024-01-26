#!/usr/bin/env bash

set -eo pipefail

cd "$(dirname "$0")/.."

# Build a config from common + overrides
package_version=$(jq -r '.packageVersion' "${CONFIG_DIR}/clients/${SDK_LANGUAGE}/config.overrides.json")

# shellcheck disable=SC2016
http_user_agent="$(package_version=$package_version envsubst '$sdk_language,$package_version' < ./config/common/config.base.json | jq -r '.userAgent')"

jq -rs --arg ua "$http_user_agent" 'reduce .[] as $item ({}; . * $item) | .userAgent = $ua' \
  "${CONFIG_DIR}/common/config.base.json" "${CONFIG_DIR}/clients/${SDK_LANGUAGE}/config.overrides.json" \
    > "${TMP_DIR}/config.json"

mkdir -p "${CLIENTS_OUTPUT_DIR}/fga-${SDK_LANGUAGE}-sdk"

# Initialize the temporary template directory
mkdir "${TMP_DIR}/template"

# Copy the shared files into temp template
cp -r "${CONFIG_DIR}/common/files/." "${TMP_DIR}/template/"

# Copy the template files into temp template
cp -r "${CONFIG_DIR}/clients/${SDK_LANGUAGE}/template/." "${TMP_DIR}/template/"

# Copy the CHANGELOG.md file into temp template
cp "${CONFIG_DIR}/clients/${SDK_LANGUAGE}/CHANGELOG.md.mustache" "${TMP_DIR}/template/"

# Clear existing directory
# shellcheck disable=SC2010,SC2012
cd "${CLIENTS_OUTPUT_DIR}/fga-${SDK_LANGUAGE}-sdk" && ls -A | { grep -Ev '.git|node_modules|.idea|venv|.gradle' || test $? = 1; } | xargs rm -r && cd -

# Copy the generator ignore file into target directory (we need to do this before build otherwise openapi-generator ignores it)
cp "${CONFIG_DIR}/clients/${SDK_LANGUAGE}/.openapi-generator-ignore" "${CLIENTS_OUTPUT_DIR}/fga-${SDK_LANGUAGE}-sdk/"

library=()
[[ -n "$LIBRARY_TEMPLATE" ]] && library=(--library "$LIBRARY_TEMPLATE")

# Generate the SDK
docker run --rm \
  -u "${CURRENT_UID}:${CURRENT_GID}" \
  -v "${PWD}/docs:/docs" \
  -v "${CLIENTS_OUTPUT_DIR}:/clients" \
  -v "${TMP_DIR}:/config" \
  --name openapi-generator \
  "openapitools/openapi-generator-cli:${OPENAPI_GENERATOR_CLI_DOCKER_TAG}" generate \
  -i /docs/openapi/openfga.openapiv2.json \
  --http-user-agent="$http_user_agent" \
  "${library[@]}" \
  -o "/clients/fga-${SDK_LANGUAGE}-sdk" \
  -c /config/config.json \
  -g "$(cat ./config/clients/"${SDK_LANGUAGE}"/generator.txt)"
