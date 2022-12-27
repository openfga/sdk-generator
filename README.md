# OpenFGA Client SDK Generator

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE)
[![Discord Server](https://img.shields.io/discord/759188666072825867?color=7289da&logo=discord "Discord Server")](https://discord.com/channels/759188666072825867/930524706854031421)
[![Twitter](https://img.shields.io/twitter/follow/openfga?color=%23179CF0&logo=twitter&style=flat-square "@openfga on Twitter")](https://twitter.com/openfga)

This is the main generator responsible for generating the OpenFGA SDKs from the [OpenFGA OpenAPIv2 Document](https://github.com/openfga/api/blob/main/docs/openapiv2/apidocs.swagger.json).

## Table of Contents

- [OpenFGA Client SDK Generator](#openfga-client-sdk-generator)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [Resources](#resources)
  - [Currently Supported SDKs](#currently-supported-sdks)
  - [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Usage](#usage)
    - [Adding a new SDK](#adding-a-new-sdk)
      - [Using the setup script](#using-the-setup-script)
      - [Manually](#manually)
    - [Uploading the SDK](#uploading-the-sdk)
    - [Publishing/Open Sourcing the SDK](#publishingopen-sourcing-the-sdk)
    - [GitHub Action Secrets](#github-action-secrets)
  - [Contributing](#contributing)
  - [Author](#author)
  - [License](#license)

## About

[OpenFGA](https://openfga.dev) is an open source Fine-Grained Authorization solution inspired by [Google's Zanzibar paper](https://research.google/pubs/pub48190/). It was created by the FGA team at [Auth0](https://auth0.com) based on [Auth0 Fine-Grained Authorization (FGA)](https://fga.dev), available under [a permissive license (Apache-2)](https://github.com/openfga/rfcs/blob/main/LICENSE) and welcomes community contributions.

OpenFGA is designed to make it easy for application builders to model their permission layer, and to add and integrate fine-grained authorization into their applications. OpenFGA’s design is optimized for reliability and low latency at a high scale.

## Resources

- [OpenFGA Documentation](https://openfga.dev/docs)
- [OpenFGA API Documentation](https://openfga.dev/api/service)
- [Twitter](https://twitter.com/openfga)
- [OpenFGA Discord Community](https://discord.gg/8naAwJfWN6)
- [Zanzibar Academy](https://zanzibar.academy)
- [Google's Zanzibar Paper (2019)](https://research.google/pubs/pub48190/)

## Currently Supported SDKs

| Language   | GitHub                                                      | Package Manager                                                           |
|------------|-------------------------------------------------------------|---------------------------------------------------------------------------|
| Javascript | [openfga/js-sdk](https://github.com/openfga/js-sdk)         | [@openfga/sdk](https://www.npmjs.com/package/@auth0/fga) on npm           |
| Go         | [openfga/go-sdk](https://github.com/openfga/go-sdk)         | -                                                                         |
| .NET       | [openfga/dotnet-sdk](https://github.com/openfga/dotnet-sdk) | [OpenFga.Sdk](https://www.nuget.org/packages/OpenFga.Sdk) on nuget        |
| PYTHON     | [openfga/python](https://github.com/openfga/python-sdk)     | [openfga-sdk](https://pypi.org/project/openfga-sdk) on PyPI               |
| PYTHON     | [openfga/python](https://github.com/openfga/python-sdk)     | [kotlin-sdk](https://central.sonatype.dev/namespace/dev.openfga) on Maven |

## Getting Started

### Requirements
1. Git
2. Docker
3. Make (Optional, but makes things much easier)
4. curl
5. Bash
6. sed

### Usage

1. Clone this repo:

```shell
git clone git@github.com:openfga/sdk-generator.git
```

2. Clone existing SDKs into the clients directory

```shell
git clone git@github.com:openfga/go-sdk.git clients/fga-go-sdk
git clone git@github.com:openfga/js-sdk.git clients/fga-js-sdk
git clone git@github.com:openfga/dotnet-sdk.git clients/fga-dotnet-sdk
git clone git@github.com:openfga/python-sdk.git clients/fga-python-sdk
git clone git@github.com:openfga/kotlin-sdk.git clients/fga-kotlin-sdk
```

3. Build and test the client sdks
```shell
make
```

### Adding a new SDK

#### Using the setup script
There is a helpful script to setup a new SDK

```shell
make setup-new-sdk
```

1. It will ask you for a an SDK ID, use something like: go, js, dotnet, java, etc...
2. It will ask you for a [valid generator](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators.md)
3. Then in will initialize all the files, you will need to add the configuration specific to that sdk
4. Now you can run `make build-client-${SDK_ID}` to generate the SDK

#### Manually

1. Create config dir in: `config/clients/{lang}/`. It should include:
   * `CHANGELOG.md`: To be updated as new releases are generated
   * `generator.txt`: the name of the generator to use. Must be a [valid generator](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators.md)
   * `config.overrides.json`: Custom config for this generator + overrides to the common config in `config/common/config.base.json`
   * `.openapi-generator-ignore`: Any files that the generator should ignore and not build
   * `template/` directory'
      * `LICENSE`: License file from legal. Note: All SDKs must be MIT Licensed.
      * `.github/workflows/tests.yml`: Any CI checks that need to run
      * The following files, each with the relevant section (look at the JS template for an example):
         * README_installation.mustache
         * README_initializing.mustache
         * README_calling_api.mustache
         * README_api_endpoints.mustache
         * README_models.mustache
         * README_license_disclaimer.mustache
      * custom files according to the generator
2. Update the `Makefile`.
   1. add a target for the new sdk
```makefile
.PHONY: build-client-{{LANG}}
build-client-{{LANG}}:
	make build-client sdk_language={{LANG}} tmpdir=${TMP_DIR}
	# ... any other custom build steps ...
```
   2. add it as a dependency to the `build-all-clients`
```makefile
.PHONY: build-all-clients
build-all-clients: build-client-js build-client-go ...  build-client-{{LANG}}
```
   3. add a target for the new sdk's tests that depend on the build target
```makefile
.PHONY: test-client-{{LANG}}
test-client-{{LANG}}: build-client-{{LANG}}
	# ... any custom test code ...
```
   4. add it as a dependency to the `test-all-clients`
```makefile
.PHONY: test-all-clients
test-all-clients: test-client-js test-client-go ...  test-client-{{LANG}}
```

### Uploading the SDK

Once the SDK is ready, you need to:
* Create a repo under the [openfga](https://github.com/openfga) github org. Call it: `${SDK_ID}-sdk`
* Add it to the generator's test and deploy actions
* Add any necessary secrets to the generator's repo on github (and document them in the readme)

### Publishing/Open Sourcing the SDK

Once the SDK is ready, you need to:
1. Setup Snyk, and ensure no security issues are present
2. Setup Fossa, and ensure no compliance issues are present
3. Request a review from the team

Note: Semgrep will be automatically enabled - there is nothing you need to do for that.

### GitHub Action Secrets

| Key                         | Comment                                |
|-----------------------------|----------------------------------------|
| `KNOWN_HOSTS`               |                                        |
| `FOSSA_API_KEY`             | FOSSA API Key                          |
| `SNYK_TOKEN`                | Snyk API Key                           |
| `GO_SDK_GITHUB_ORG_ID`      | The GitHub org for the SDK             |
| `GO_SDK_GITHUB_REPO_ID`     | The GitHub repo id for the SDK         |
| `GO_SDK_SSH_KEY`            | The SSH private deploy key for the SDK |
| `JS_SDK_GITHUB_ORG_ID`      | The GitHub org for the SDK             |
| `JS_SDK_GITHUB_REPO_ID`     | The GitHub repo id for the SDK         |
| `JS_SDK_SSH_KEY`            | The SSH private deploy key for the SDK |
| `DOTNET_SDK_GITHUB_ORG_ID`  | The GitHub org for the SDK             |
| `DOTNET_SDK_GITHUB_REPO_ID` | The GitHub repo id for the SDK         |
| `DOTNET_SDK_SSH_KEY`        | The SSH private deploy key for the SDK |
| `PYTHON_SDK_GITHUB_ORG_ID`  | The GitHub org for the SDK             |
| `PYTHON_SDK_GITHUB_REPO_ID` | The GitHub repo id for the SDK         |
| `PYTHON_SDK_SSH_KEY`        | The SSH private deploy key for the SDK |
| `KOTLIN_SDK_GITHUB_REPO_ID` | The GitHub repo id for the SDK         |
| `KOTLIN_SDK_SSH_KEY`        | The SSH private deploy key for the SDK |


The following keys are also available but should be considered deprecated. Automated release is disabled due to the complexity of generating relevant commit messages when using a generator.

| Key                          | Comment                                                               |
|------------------------------|-----------------------------------------------------------------------|
| `GIT_USER_EMAIL`             | Email of the user in the git commits                                  |
| `GIT_USER_NAME`              | Name of the user in the git commits                                   |
| `GO_SDK_DRY_RUN`             | Whether to show git diff and exit without pushing changes for the SDK |
| `GO_SDK_TAGGING_DISABLE`     | Whether to disable tagging and publishing for the SDK                 |
| `JS_SDK_DRY_RUN`             | Whether to show git diff and exit without pushing changes for the SDK |
| `JS_SDK_TAGGING_DISABLE`     | Whether to disable tagging and publishing for the SDK                 |
| `NPM_EMAIL`                  | The email of the user pushing to npm                                  |
| `NPM_TOKEN`                  | The token of the user pushing to npm                                  |
| `DOTNET_SDK_DRY_RUN`         | Whether to show git diff and exit without pushing changes for the SDK |
| `DOTNET_SDK_TAGGING_DISABLE` | Whether to disable tagging and publishing for the SDK                 |
| `KOTLIN_SDK_DRY_RUN`         | Whether to show git diff and exit without pushing changes for the SDK |
| `KOTLIN_SDK_TAGGING_DISABLE` | Whether to disable tagging and publishing for the SDK                 |

## Contributing
Please review the [Contributing Guidelines](https://github.com/openfga/.github/blob/main/CONTRIBUTING.md) before sending a PR or opening an issue.

In addition, we ask that the SDKs:

* be generated from the [openapiv2 swagger document](https://github.com/openfga/api/blob/main/docs/openapiv2/apidocs.swagger.json) using the sdk-generator.

* have roughly the same consistent interface for configuration, such as [JS](https://github.com/openfga/js-sdk), [GoLang](https://github.com/openfga/go-sdk), [.NET](https://github.com/openfga/dotnet-sdk) and [Python](https://github.com/openfga/python-sdk) SDKs.

* support the same features with other existing SDKs.

* have a base set of functional tests.

* have no tests that talk to an external service (external calls should be disallowed and mocked).

* have building & publishing automated through GitHub actions.

* be created and modified through pull requests to this sdk-generator repository instead of individual repositories. Most of the code will be in mustache files that will end up generating the resulting SDK for the appropriate language.

## Author

[OpenFGA](https://github.com/openfga)

## License

This project is licensed under the Apache-2.0 license. See the [LICENSE](https://github.com/openfga/sdk-generator/blob/main/LICENSE) file for more info.

The template files in this repo are based on the original files from [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator).
