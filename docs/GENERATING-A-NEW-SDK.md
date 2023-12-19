# Generating a new SDK for OpenFGA

Thanks for your interest in generating a new SDK for the [OpenFGA](https://openfga.dev)
project.

## Table of Contents

- [Generating a new SDK for OpenFGA](#generating-a-new-sdk-for-openfga)
  - [Table of Contents](#table-of-contents)
  - [Tenets](#tenets)
    - [Consistency](#consistency)
    - [Dependency-light](#dependency-light)
  - [Adding a new SDK](#adding-a-new-sdk)
    - [Using the setup script](#using-the-setup-script)
    - [Manually](#manually)
    - [Updating the notice files](#updating-the-notice-files)
  - [Laying a foundation](#laying-a-foundation)
    - [Adjusting defaults](#adjusting-defaults)
    - [Testing basic functionality](#testing-basic-functionality)
    - [Remove unnecessary files](#remove-unnecessary-files)
  - 

## Tenets

There is a small group of core contributors to the project, and they will not
be experts in every language supported. Therefore, there are some guiding
principles from the team that help determine the direction of strategic and
technical choices for the SDKs we can produce and support.

### Consistency

Contributors need consistency. It's unlikely that an end-user will use the SDK
in many languages, but an OpenFGA contributor must be able to maintain and
extend SDKs even for languages they are not an expert in. To help ensure a
contributor to the OpenFGA can be effective, the project strives for 
consistency between SDK implementations in different languages.

More specifically this means the features, logic, and behavior should be as
identical as possible within the semantics of a given language. Surface-level
concerns like naming, errors/exceptions, APIs, structure, and organization of
the SDKs should be very similar.

Change is sometimes necessary, and an improvement must start as inconsistent
implementation. That said, consistency across implementations ensures that we
can take a positive improvement from one language, and drive that change across
multiple languages more easily if they are consistent.

### Dependency-light

OpenFGA SDKs try to avoid as many dependencies as possible. For end users this
makes OpenFGA easier to incorporate and less effort to maintain. For
contributors this makes OpenFGA SDKs less effort to maintain, and requires
following and responding to change in less projects.

For end-users, there should be no need to request an SDK implementation any
more specific than the language you use. As an example, for Java we use the
standard library's built-in [`HttpClient`](https://openjdk.org/groups/net/httpclient/intro.html).
This allows OpenFGA to work with an end-user's project without requiring or
restricting other HTTP dependencies.

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
   * `.openapi-generator-ignore`: Any files that the generator should ignore and not built
   * `template-source`: Newer SDKs should have this to mark what commit of the generator we branched off
   * `template/` directory
      * `LICENSE`: Apache-2.0 License
      * `.github/workflows/main.yml`: Any CI checks that need to run
      * The following files, each with the relevant section (look at the JS template for an example):
         * `README_installation.mustache`
         * `README_initializing.mustache`
         * `README_calling_api.mustache`
         * `README_api_endpoints.mustache`
         * `README_models.mustache`
         * `README_license_disclaimer.mustache`
         * `README_custom_badges.mustache` (optional, any custom badges for this specific SDK)
         * `gitignore_custom.mustache` (optional, any custom ignores for this specific SDK)
         * `NOTICE_details.mustache` (optional, see [Updating the Notice files](#updating-the-notice-files))
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

> Note: Try to ensure that the SDK is built through container files so that other contributors would not need to set up the full language framework/toolchain whenever they need to contribute. Checkout the [go sdk build steps](https://github.com/openfga/sdk-generator/blob/bf6709a5faba14ce260f4f8df019dddd54078df0/Makefile#L76) as an example.

### Updating the Notice files

1- Ensure that `fossaComplianceNoticeId` has been set in each SDK's config overrides.
2- Run `make update-fossa-reports`

## Laying a foundation

After [adding a new SDK](#adding-a-new-sdk), some light work may be required
for correctness and functionality.

### Adjusting defaults

Some of the defaults from OpenAPI generator may not make sense for OpenFGA, or
they may be inconsistent with options used by other OpenFGA SDKs. Take time to
review the options for the generator for your language and the options it
provides.

Some configurations can impact all usage of the SDK, like whether to use the
asynchronous features of a language. Other configurations may not affect the
code at all, but be critical in other ways, like links in project metadata to
the OpenFGA project website.

Find [the documentation for your generator and its configuration](https://github.com/OpenAPITools/openapi-generator/tree/master/docs/generators#readme).
Make adjustments or additions as needed to the OpenAPI Generator inputs found
in `config/clients/<LANG>/config.overrides.json`.

Where possible, consider replacing mustache references to these overrides with
common overrides found in `config/common/config.base.json`.

### Testing basic functionality

At this point the SDK should have a low-level client with a name similar to
`OpenFgaApi`. It should be possible to use that to perform HTTP requests
against a testing OpenFGA server running unprotected locally on the same
machine.

1. With Docker installed, run a basic local server with the command:
```
docker run -p 8080:8080 -p 3000:3000 openfga/openfga run
```

2. The output from the docker command will have a message like:
   `starting openfga playground on http://localhost:3000/playground`
  1. Open this playground URL in your browser of choice.
  2. In the playground create a store with the button labeled `NEW STORE`
  3. After creating the store, use the button labeled `SAVE` to save the
      default authorization model.
  4. Use the `⋮` menu in the top right of the playground and copy both the
     "Store ID" and the "Authorization Model ID"

3. Using your generated client, make calls to the local OpenFGA server from
   step 1 above. You can use OpenFGA's [Getting Started](https://openfga.dev/docs/getting-started)
   guide for example calls you can make, and the output to expect.

4. Make any necessary adjustments to the SDK for it to behave correctly.

Consider using this as an opportunity to contribute integration tests. The Java
SDK and its `test-integration-client-java` Make target in the project's
`Makefile` can be referenced for introducing an integration test.

### Remove unnecessary files

Take this time to remove unnecessary files.

Especially if you were [using the setup script](#using-the-setup-script),
there will be unused files (and possibly unused directories of files) that are
only used for alternative software choices like HTTP libaries, build and
packaging tools, frameworks, test libraries, serialization/deserialization
libraries, or other CI/CD services that will not be used in your SDK.

Remove the unnecessary mustache template files from the source code. If the
file is still rendered when building the SDK, also add it to the
`config/clients/<LANG>/.openapi-generator-ignore` file.

## Quality requirements

TODO: Detail basic quality requirements (tests, linter, formatter)
TODO: Point to example build/publish CI workflows

## Low-level client

### Configuration

TODO: Configuration spec
TODO: Expected low-level client function signatures. Mention storeId first (where applicable), then params, then configurations

### Per-request override

TODO

## High-level client

### Implementation strategy

TODO: Detail commonalities between high level clients in naming and function signatures
TODO: Detail the request/response/options shapes

### Authentication

TODO: Credential types. None, Static, OAuth2
TODO: Link to [Client Credentials Flow](https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow) and detail implementation
TODO: Detail on naming and how/where to integrate an OAuth2Client

### Client-side APIs

TODO: Detail BatchCheck
TODO: Detail ListRelations
TODO: Detail non-transactional Write

## Retry

TODO: Mention retry defaults (reference from common configs)
TODO: Detail the behavior (4xx and 529; both on "OpenFgaApi" and on "OAuth2Client")

## Errors

TODO: List the types of errors and the cases that should throw them

## Documentation

TODO: Explain how to check auto-generated docs
TODO: Write something about language-specific docs (e.g. stuff that gets rendered to pkg.go.dev, javadoc.io, docs.rs, etc)
