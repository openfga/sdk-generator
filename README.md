# OpenFGA Client SDK Generator

## Requirements
1. Git
2. Docker
3. Make (Optional, but makes things much easier)
4. curl
5. Bash
6. sed

## Usage

1. Clone this repo:

```shell
git clone git@github.com:openfga/sdk-generator.git
```

2. Clone existing SDKs into the clients directory

```shell
git clone git@github.com:openfga/go-sdk.git clients/fga-go-sdk
git clone git@github.com:openfga/js-sdk.git clients/fga-js-sdk
git clone git@github.com:openfga/dotnet-sdk.git clients/fga-dotnet-sdk
```

3. Build and test the client sdks
```shell
make
```

## Adding a new SDK

### Using the setup script
There is a helpful script to setup a new SDK

```shell
make setup-new-sdk
```

1. It will ask you for a an SDK ID, use something like: go, js, dotnet, java, etc...
2. It will ask you for a [valid generator](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators.md)
3. Then in will initialize all the files, you will need to add the configuration specific to that sdk
4. Now you can run `make build-client-${SDK_ID}` to generate the SDK

### Manually

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

## Uploading the SDK

Once the SDK is ready, you need to:
* Create a repo under the [openfga](https://github.com/openfga) github org. Call it: `${SDK_ID}-sdk`
* Add it to the generator's test and deploy actions
* Add any necessary secrets to the generator's repo on github (and document them in the readme)

## Publishing/Open Sourcing the SDK

Once the SDK is ready, you need to:
1. Setup Snyk, and ensure no security issues are present
2. Setup Fossa, and ensure no compliance issues are present
3. Request a review from the team

Note: Semgrep will be automatically enabled - there is nothing you need to do for that.

## GitHub Action Secrets

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
