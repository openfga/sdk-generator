# Main config
OPENFGA_DOCKER_TAG = v1.4.0
OPEN_API_REF ?= main
OPEN_API_URL = https://raw.githubusercontent.com/openfga/api/${OPEN_API_REF}/docs/openapiv2/apidocs.swagger.json
OPENAPI_GENERATOR_CLI_DOCKER_TAG = v6.4.0
NODE_DOCKER_TAG = 20-alpine
GO_DOCKER_TAG = 1
DOTNET_DOCKER_TAG = 6.0
GOLINT_DOCKER_TAG = v1.54-alpine
BUSYBOX_DOCKER_TAG = 1
GRADLE_DOCKER_TAG = 8.2
PYTHON_DOCKER_TAG = 3.10
# Other config
CONFIG_DIR = ${PWD}/config
CLIENTS_OUTPUT_DIR = ${PWD}/clients
DOCS_CACHE_DIR = ${PWD}/docs/openapi
TMP_DIR = $(shell mktemp -d "$${TMPDIR:-/tmp}/tmp.XXXXX")
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

all: test-all-clients

## Refresh Docker Images
pull-docker-images:
	docker pull openfga/openfga:${OPENFGA_DOCKER_TAG}
	docker pull openapitools/openapi-generator-cli:${OPENAPI_GENERATOR_CLI_DOCKER_TAG}
	docker pull node:${NODE_DOCKER_TAG}
	docker pull golang:${GO_DOCKER_TAG}
	docker pull golangci/golangci-lint:${GOLINT_DOCKER_TAG}
	docker pull mcr.microsoft.com/dotnet/sdk:${DOTNET_DOCKER_TAG}
	docker pull busybox:${BUSYBOX_DOCKER_TAG}
	docker pull gradle:${GRADLE_DOCKER_TAG}

## Building and Testing
.PHONY: test
test: test-all-clients

.PHONY: build
build: build-all-clients

.PHONY: test-all-clients
test-all-clients: test-client-js test-client-go test-client-dotnet test-client-python test-client-java

.PHONY: build-all-clients
build-all-clients: build-client-js build-client-go build-client-dotnet build-client-python build-client-java

### JavaScript
.PHONY: tag-client-js
tag-client-js: test-client-js
	make utils-tag-client sdk_language=js

.PHONY: test-client-js
test-client-js: build-client-js
	make run-in-docker sdk_language=js image=node:${NODE_DOCKER_TAG} command="/bin/sh -c 'npm test && npm audit && npm run lint'"

.PHONY: build-client-js
build-client-js:
	make build-client sdk_language=js tmpdir=${TMP_DIR}
	sed -i -e "s|_this|this|g" ${CLIENTS_OUTPUT_DIR}/fga-js-sdk/*.ts
	sed -i -e "s|_this|this|g" ${CLIENTS_OUTPUT_DIR}/fga-js-sdk/*.md
	rm -rf  ${CLIENTS_OUTPUT_DIR}/fga-js-sdk/*-e
	make run-in-docker sdk_language=js image=node:${NODE_DOCKER_TAG} command="/bin/sh -c 'npm i --lockfile-version 2 && npm run lint:fix -- --quiet'"
	make run-in-docker sdk_language=js image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/api.ts /config/clients/js/patches/add-missing-first-param.patch'"
	make run-in-docker sdk_language=js image=node:${NODE_DOCKER_TAG} command="/bin/sh -c 'npm run lint:fix && npm run build;'"

### Go
.PHONY: tag-client-go
tag-client-go: test-client-go
	make utils-tag-client sdk_language=go

.PHONY: test-client-go
test-client-go: build-client-go
	make run-in-docker sdk_language=go image=golang:${GO_DOCKER_TAG} command="/bin/sh -c 'go test -v ./...'"
	make run-in-docker sdk_language=go image=golang:${GO_DOCKER_TAG} command="/bin/sh -c 'go install golang.org/x/vuln/cmd/govulncheck@latest; govulncheck ./...;'"
	make run-in-docker sdk_language=go image=golangci/golangci-lint:${GOLINT_DOCKER_TAG} command="golangci-lint run -v --skip-files=oauth2/"

.PHONY: build-client-go
build-client-go:
	make build-client sdk_language=go tmpdir=${TMP_DIR}
	make run-in-docker sdk_language=go image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/api_open_fga.go /config/clients/go/patches/add-missing-first-param.patch'"
	make run-in-docker sdk_language=go image=golang:${GO_DOCKER_TAG} command="/bin/sh -c 'gofmt -w .'"

### .NET
.PHONY: tag-client-dotnet
tag-client-dotnet: test-client-dotnet
	make utils-tag-client sdk_language=dotnet

.PHONY: test-client-dotnet
test-client-dotnet: build-client-dotnet
	make run-in-docker sdk_language=dotnet image=mcr.microsoft.com/dotnet/sdk:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet test'"

.PHONY: build-client-dotnet
build-client-dotnet:
	rm -rf ${CLIENTS_OUTPUT_DIR}/fga-dotnet-sdk/src/OpenFga.Sdk.Test
	make build-client sdk_language=dotnet tmpdir=${TMP_DIR}

	make run-in-docker sdk_language=dotnet image=mcr.microsoft.com/dotnet/sdk:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet build --configuration Release'"
	# For some reason the first round of formatting fails with an error - running it again produces the correct result
	make run-in-docker sdk_language=dotnet image=mcr.microsoft.com/dotnet/sdk:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet format ./OpenFga.Sdk.sln'" || true
	make run-in-docker sdk_language=dotnet image=mcr.microsoft.com/dotnet/sdk:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet format ./OpenFga.Sdk.sln'"

### Python
.PHONY: tag-client-python
tag-client-python: test-client-python
	make utils-tag-client sdk_language=python

.PHONY: build-client-python
build-client-python:
	make build-client sdk_language=python tmpdir=${TMP_DIR} library="asyncio"
	mv ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/openfga_sdk/api/open_fga_api_sync.py ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/openfga_sdk/sync/open_fga_api.py # TODO: Remove on OpenAPI generator v7.1 or higher
	make run-in-docker sdk_language=python image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/openfga_sdk/api/open_fga_api.py /config/clients/python/patches/open_fga_api.py.patch'"
	make run-in-docker sdk_language=python image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/openfga_sdk/sync/open_fga_api.py /config/clients/python/patches/open_fga_api_sync.py.patch'"
	make run-in-docker sdk_language=python image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/docs/OpenFgaApi.md /config/clients/python/patches/OpenFgaApi.md.patch'"
	make run-in-docker sdk_language=python image=python:${PYTHON_DOCKER_TAG} command="/bin/sh -c 'python -m pip install pyupgrade==3.15.1 isort==5.13.2 black==24.2.0 autoflake==2.3.0; pyupgrade \`find . -name *.py -type f\` --py310-plus --keep-runtime-typing; isort . --profile black; black .; autoflake --exclude=__init__.py --in-place --remove-unused-variables --remove-all-unused-imports -r .'"
	make run-in-docker sdk_language=python image=python:${PYTHON_DOCKER_TAG} command="/bin/sh -c 'pip install setuptools wheel && python setup.py sdist bdist_wheel'"

.PHONY: test-client-python
test-client-python: build-client-python
	make run-in-docker sdk_language=python image=python:${PYTHON_DOCKER_TAG} command="/bin/sh -c 'python -m pip install -r test-requirements.txt; pytest; flake8 . --count --show-source --statistics'"

### Java
.PHONY: tag-client-java
tag-client-java: test-client-java
	make utils-tag-client sdk_language=java

.PHONY: build-client-java
build-client-java:
	make build-client sdk_language=java tmpdir=${TMP_DIR}
	make run-in-docker sdk_language=java image=gradle:${GRADLE_DOCKER_TAG} command="/bin/sh -c 'chmod +x ./gradlew && gradle fmt build'"

.PHONY: test-client-java
test-client-java: build-client-java
	make run-in-docker sdk_language=java image=gradle:${GRADLE_DOCKER_TAG} command="/bin/sh -c 'gradle test'"

.PHONY: test-integration-client-java
test-integration-client-java: test-client-java
	docker container rm --force openfga-for-java-client || true
	docker run --detach --name openfga-for-java-client -p 8080:8080 openfga/openfga:${OPENFGA_DOCKER_TAG} run
	make run-in-docker sdk_language=java image=gradle:${GRADLE_DOCKER_TAG} command="/bin/sh -c 'gradle test-integration'"
	docker container rm --force openfga-for-java-client

.PHONY: run-in-docker
run-in-docker:
	docker run --rm \
		-v "${CLIENTS_OUTPUT_DIR}/fga-${sdk_language}-sdk":/module \
		-v ${CONFIG_DIR}:/config \
		-w /module \
		--net="host" \
		${image} \
		${command}

.EXPORT_ALL_VARIABLES:
.PHONY: build-client
build-client: build-openapi
	SDK_LANGUAGE="${sdk_language}" TMP_DIR="${tmpdir}" LIBRARY_TEMPLATE="${library}"\
		./scripts/build_client.sh

.PHONY: build-openapi
build-openapi: init get-openapi-doc
	cat "${DOCS_CACHE_DIR}/openfga.openapiv2.raw.json" | \
		jq '(.. | .tags? | select(.)) |= ["OpenFga"] | (.tags? | select(.)) |= [{"name":"OpenFga"}] | del(.definitions.ReadTuplesParams, .definitions.ReadTuplesResponse, .paths."/stores/{store_id}/read-tuples", .definitions.StreamedListObjectsRequest, .definitions.StreamedListObjectsResponse, .paths."/stores/{store_id}/streamed-list-objects")' > \
		${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/v1.//g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json

.PHONY: get-openapi-doc
get-openapi-doc:
	mkdir -p "${DOCS_CACHE_DIR}"
	curl "${OPEN_API_URL}" \
	     -o "${DOCS_CACHE_DIR}/openfga.openapiv2.raw.json"

# Note you need to make sure fossaComplianceNoticeId has been set in the config overrides before running this
.PHONY: update-fossa-reports
update-fossa-reports:
	make update-fossa-report-js
	make update-fossa-report-go
	make update-fossa-report-python
	make update-fossa-report-dotnet

.PHONY: update-fossa-report-js
update-fossa-report-js:
	make utils-update-fossa-report sdk_language=js

.PHONY: update-fossa-report-go
update-fossa-report-go:
	make utils-update-fossa-report sdk_language=go

.PHONY: update-fossa-report-dotnet
update-fossa-report-dotnet:
	make utils-update-fossa-report sdk_language=dotnet

.PHONY: update-fossa-report-python
update-fossa-report-python:
	make utils-update-fossa-report sdk_language=python

.PHONY: utils-update-fossa-report
utils-update-fossa-report:
	cd config/clients/${sdk_language} && \
		echo https://app.fossa.com/attribution/`cat config.overrides.json | jq -r ".fossaComplianceNoticeId"` | \
		xargs curl -Lo "template/NOTICE_details.mustache"

.PHONY: utils-tag-client
utils-tag-client:
	cd clients/fga-${sdk_language}-sdk && \
		git tag -a -s v`cat VERSION.txt`
	# now run: cd clients/fga-${sdk_language}-sdk && git push origin tag vA.B.C

.PHONY: init
init: ensure-dirs

.PHONY: ensure-dirs
ensure-dirs:
	mkdir -p "${DOCS_CACHE_DIR}/" "${CLIENTS_OUTPUT_DIR}/"

.PHONY: shellcheck
shellcheck:
	docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable scripts/*

.PHONY: setup-new-sdk
setup-new-sdk:
	./scripts/setup_new_sdk.sh
