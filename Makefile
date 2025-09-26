# Main config
OPENFGA_DOCKER_TAG = v1
OPEN_API_REF ?= e53c69cc55317404d02a6d8e418d626268f28a59
OPEN_API_URL = https://raw.githubusercontent.com/openfga/api/${OPEN_API_REF}/docs/openapiv2/apidocs.swagger.json
OPENAPI_GENERATOR_CLI_DOCKER_TAG ?= v6.4.0
NODE_DOCKER_TAG = 20-alpine
GO_DOCKER_TAG = 1
DOTNET_DOCKER_TAG = 9.0
GOLINT_DOCKER_TAG = latest-alpine
BUSYBOX_DOCKER_TAG = 1
GRADLE_DOCKER_TAG = 8.12-jdk17
PYTHON_DOCKER_TAG = 3.10
# Other config
CONFIG_DIR = ${PWD}/config
CLIENTS_OUTPUT_DIR = ${PWD}/clients
DOCS_CACHE_DIR = ${PWD}/docs/openapi
TMP_DIR = $(shell mktemp -d "$${TMPDIR:-/tmp}/tmp.XXXXX")
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
# Determine if Docker is being used via Docker Desktop, if so we need to tell testcontainers to
# use the Docker Desktop host. We can't just always set this because GitHub Actions will fail.
DOCKER_PLATFORM := $(shell docker version -f json | jq .Server.Platform.Name)
ifeq ($(findstring Docker Desktop,$(DOCKER_PLATFORM)),Docker Desktop)
	TEST_CONTAINERS_ENV=-e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal
endif

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

## Build custom Docker images
build-docker-images: build-dotnet-multi-image

.PHONY: build-dotnet-multi-image
build-dotnet-multi-image:
	docker build -f docker/dotnet-multi.Dockerfile -t openfga/dotnet-multi:${DOTNET_DOCKER_TAG} .

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
	make run-in-docker sdk_language=go image=golang:${GO_DOCKER_TAG} command="/bin/sh -c 'gofmt -w . && go mod tidy'"
	find ${CLIENTS_OUTPUT_DIR}/fga-go-sdk/example -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | while read example_dir; do \
		make run-in-docker sdk_language=go image=golang:${GO_DOCKER_TAG} command="/bin/sh -c 'cd example/$$example_dir && gofmt -w . && go mod tidy'"; \
	done

### .NET
.PHONY: tag-client-dotnet
tag-client-dotnet: test-client-dotnet
	make utils-tag-client sdk_language=dotnet

.PHONY: test-client-dotnet
test-client-dotnet: build-client-dotnet build-dotnet-multi-image
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet test'"

.PHONY: build-client-dotnet
build-client-dotnet: build-dotnet-multi-image
	rm -rf ${CLIENTS_OUTPUT_DIR}/fga-dotnet-sdk/src/OpenFga.Sdk.Test
	make build-client sdk_language=dotnet tmpdir=${TMP_DIR}

	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet build --configuration Release'"
	# Workaround for dotnet format issue: https://github.com/dotnet/format/issues/1634
	# Format with single target (net8.0) to avoid merge conflicts, then restore multi-targeting
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'cp src/OpenFga.Sdk/OpenFga.Sdk.csproj src/OpenFga.Sdk/OpenFga.Sdk.csproj.bak'"
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'sed \"s/<TargetFrameworks>.*<\/TargetFrameworks>/<TargetFramework>net8.0<\/TargetFramework>/\" src/OpenFga.Sdk/OpenFga.Sdk.csproj.bak > src/OpenFga.Sdk/OpenFga.Sdk.csproj'"
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet restore ./OpenFga.Sdk.sln && dotnet format ./OpenFga.Sdk.sln'" || true
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'dotnet restore ./OpenFga.Sdk.sln && dotnet format ./OpenFga.Sdk.sln'" || true
	make run-in-docker sdk_language=dotnet image=openfga/dotnet-multi:${DOTNET_DOCKER_TAG} command="/bin/sh -c 'mv src/OpenFga.Sdk/OpenFga.Sdk.csproj.bak src/OpenFga.Sdk/OpenFga.Sdk.csproj'"

### Python
.PHONY: tag-client-python
tag-client-python: test-client-python
	make utils-tag-client sdk_language=python

.PHONY: build-client-python
build-client-python:
	make build-client-streamed sdk_language=python tmpdir=${TMP_DIR} library="asyncio"

	mv ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/openfga_sdk/api/open_fga_api_sync.py ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/openfga_sdk/sync/open_fga_api.py
	mv ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/test/test_open_fga_api.py ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/test/api/open_fga_api_test.py
	mv ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/test/_/*.py ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/test/ && rm -rf ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/test/_/

	sort -uo ${CLIENTS_OUTPUT_DIR}/fga-python-sdk/.openapi-generator/FILES{,}

	make run-in-docker sdk_language=python image=busybox:${BUSYBOX_DOCKER_TAG} command="/bin/sh -c 'patch -p1 /module/openfga_sdk/api/open_fga_api.py /config/clients/python/patches/open_fga_api.py.patch && \
		patch -p1 /module/openfga_sdk/sync/open_fga_api.py /config/clients/python/patches/open_fga_api_sync.py.patch && \
		patch -p1 /module/docs/OpenFgaApi.md /config/clients/python/patches/OpenFgaApi.md.patch'"

	make run-in-docker sdk_language=python image=ghcr.io/astral-sh/uv:python${PYTHON_DOCKER_TAG}-alpine command="/bin/sh -c 'export UV_LINK_MODE=copy && \
		uv sync && \
		uv run ruff check --select I --fix . && \
		uv run ruff format . && \
		uv build'"

.PHONY: test-client-python
test-client-python: build-client-python
	make run-in-docker sdk_language=python image=ghcr.io/astral-sh/uv:python${PYTHON_DOCKER_TAG}-alpine command="/bin/sh -c 'export UV_LINK_MODE=copy && \
		uv sync && \
		uv run pytest --cov-report term-missing --cov=openfga_sdk test/ && \
		uv run ruff check .'"

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
	make run-in-docker sdk_language=java image=gradle:${GRADLE_DOCKER_TAG} command="/bin/sh -c 'gradle test-integration'"

.PHONY: run-in-docker
run-in-docker:
	docker run --rm \
		-v "${CLIENTS_OUTPUT_DIR}/fga-${sdk_language}-sdk":/module \
		-v ${CONFIG_DIR}:/config \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-w /module \
		$(TEST_CONTAINERS_ENV) \
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
	sed -i -e 's/"Object"/"FgaObject"/g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/#\/definitions\/Object"/#\/definitions\/FgaObject"/g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/v1.//g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json

.EXPORT_ALL_VARIABLES:
.PHONY: build-client-streamed
build-client-streamed: build-openapi-streamed
	SDK_LANGUAGE="${sdk_language}" TMP_DIR="${tmpdir}" LIBRARY_TEMPLATE="${library}"\
		./scripts/build_client.sh

.PHONY: build-openapi-streamed
build-openapi-streamed: init get-openapi-doc
	cat "${DOCS_CACHE_DIR}/openfga.openapiv2.raw.json" | \
		jq '(.. | .tags? | select(.)) |= ["OpenFga"] | (.tags? | select(.)) |= [{"name":"OpenFga"}] | del(.definitions.ReadTuplesParams, .definitions.ReadTuplesResponse, .paths."/stores/{store_id}/read-tuples")' > \
		${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/"Object"/"FgaObject"/g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/#\/definitions\/Object"/#\/definitions\/FgaObject"/g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json
	sed -i -e 's/v1.//g' ${DOCS_CACHE_DIR}/openfga.openapiv2.json

.PHONY: get-openapi-doc
get-openapi-doc:
	mkdir -p "${DOCS_CACHE_DIR}"
	curl "${OPEN_API_URL}" \
	     -o "${DOCS_CACHE_DIR}/openfga.openapiv2.raw.json"

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
