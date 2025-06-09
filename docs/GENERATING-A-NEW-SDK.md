# Generating a new OpenFGA SDK

> Note: This document is a work in progress and is not yet complete

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
  - [Quality requirements](#quality-requirements)
  - [Low-level client](#low-level-client)
    - [Configuration](#configuration)
    - [Per-request override](#per-request-override)
    - [Authentication](#authentication)
  - [High-level client](#high-level-client)
    - [Implementation strategy](#implementation-strategy)
    - [Client-side APIs](#client-side-apis)
  - [Retry](#retry)
  - [Errors](#errors)
  - [Documentation](#documentation)

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

### Static analysis tools

An SDK should ship with basic static analysis tools. These should be at the least:

1. A test runner for unit tests against the SDK in isolation
2. A linter that can fail a build for code that is not formatted idiomatically, and
3. A formatter that can automatically format code to some idiomatic format

These tools should be test/development dependencies, and should not be inherited
or required by end users of the SDK.

### Continuous development

OpenFGA is hosted on GitHub and makes use of GitHub Actions for its CI/CD workflows.

TODO: Point to example build/publish CI workflows

## Low-level client

The following is a specification for a "low-level client" called something like `OpenFgaApi`.
This is the basic client that OpenAPI Generator will produce. It should already deal directly
with the serialization of requests, construction and dispatch of low-level HTTP requests, and
the deserialization of responses.

Each operation should follow common [Function signatures](#function-signatures). These should
[Handle HTTP headers](#handle-http-headers) including [Oauth2 access tokens](#oauth2-access-tokens).

In addition, the low-level client should support [Configuration](#configuration) and
[Per-request Override](#per-request-override).

The low-level client should contain:

* [Configuration](#configuration-1) configuration
* [OAuth2Client](#oauth2client) oAuth2Client
* Any other incidental configurations, for example the Java SDK contains an "ApiClient" from
  OpenAPI Generator. It's not necessary to restructure these incidental constructs.

### Function signatures

Functions of the low-level client should:

* Take as input a String `storeId`
  * `CreateStore` and `ListStores` are the only operations that do not take/require a `storeId`
  * The `storeId` should be validated as a non-null, non-blank String
* If applicable for the operation, take as input a modeled request `body`
  * For example, `Check` should take a `CheckRequest` as its request `body`
  * The `body` should at minimum be validated as non-null
* If it is a paginated operation, it should take as optional inputs an Integer `pageSize`
  and a String `continuationToken`
* Take as an optional input a [`ConfigurationOverride`](#per-request-override)
* Produce as output a promise/future that will complete with:
  * HTTP response details. This includes the status code, headers, and raw response body
  * If applicable for the operation, a modeled request response

### Handle HTTP headers

TODO

#### OAuth2 Access Tokens

TODO

### Configuration

#### BaseConfiguration

All *Configuration types should provide the following:

* String `apiUrl`
  * A URL for calling an OpenFGA server.
* String `userAgent`
  * A value for a `User-Agent` HTTP header.
* Temporal `readTimeout`
  * The time before an HTTP read will timeout.
* Temporal `connectTimeout`
  * The time before an HTTP connection will timeout.
* Integer `maxRetries`
  * For HTTP 429 and 5XX response codes, the maximum number retries that can be performed. See also: [Retry](#retry)
* Temporal `minimumRetryDelay`
  * For HTTP 429 and 5XX retries, the minimum amount of time between retries. See also: [Retry](#retry)

BaseConfiguration can be implemented with language features like interfaces, abstract classes, or traits where appropriate.

Follow your language's conventions for how these should be presented. For example in Java, these are implemented as "getter" methods of an interface (like `getApiUrl()`), and classes that implement the interface implement these as private fields exposed by the public "getter" methods.

#### Configuration

In addition to the fields of [BaseConfiguration](#baseconfiguration), Configuration should contain:

* [`Credentials`](#credentials) `credentials`
* Map or associative array `defaultHeaders`
  * Keys and values should be a String type
  * Any headers to apply by default (i.e. not overridden) to all requests of an OpenFGA client.

The `Configuration` should provide the following default values:

| Attribute        | Value                     | Mustache source                  |
|------------------|---------------------------|----------------------------------|
| `apiUrl`         | `"http://localhost:8080"` | N/A                              |
| `userAgent`      | `"{{{userAgent}}}"`       | `config/common/config.base.json` |
| `readTimeout`    | 10 seconds                | N/A                              |
| `connectTimeout` | 10 seconds                | N/A                              |

`Configuration` should also have an `assertValid()` function that evaluates the validity
of `Configuration`. This should require that:

* `apiUrl` is unset or is a valid URL. A valid URL has a scheme and hostname, and any
  optional URL components should be valid. In some languages this check can be accomplished
  simply by constructing some `URL` type from the language's standard library.
  * Note: It is not an error for the `apiUrl` to be unset. If it is null, nil, None, etc then
    the `apiUrl` should resolve to the default value above.
* `credentials` is unset or is a valid credential as described in the [`Credentials`](#credentials)
  `assertValid()` specification.

#### ClientConfiguration

In addition to the fields of [Configuration](#configuration) and [BaseConfiguration](#baseconfiguration),
ClientConfiguration should contain

* String `storeId`
* String `authorizationModelId`

### Per-request override

The low-level client should allow an optional `ConfigurationOverride` as input for each of its
operations. The `ConfigurationOverride` should have the same properties as [`Configuration`](#configuration-1) with one exception:

* Instead of `defaultHeaders`, the override should have an `additionalHeaders` of the same type

When resolving the client's [`Configuration`](#configuration-1) with `ConfigurationOverride`,
do not modify either the `Configuration` or the `ConfigurationOverride`. If necessary, construct
a new intermediate `Configuration` for the context of an operation.

The resolved configuration values should follow these rules:

1. For all non-header properties, if a `ConfigurationOverride` property is set, that is the resolved value.
   Otherwise the resolved value will be identical to the `Configuration` property.
2. Headers are merged with the following rules:
   1. If a header is set in `ConfigurationOverride`, it should be resolved as this header and take
      precedence over a value set in the `Configuration`
   2. If a header is explicitly set to a null value (null, nil, None, etc) then it should be resolved
      as an un-set header, even if `Configuration` has the header
   3. Any other headers from `Configuration` should be preserved
   4. The `defaultHeaders` of the `Configuration` should be unmodified during resolution
   5. The `additionalHeaders` of the `ConfigurationOverride` should be unmodified during resolution

### Authentication

#### OAuth2Client

The OAuth2Client is an abstraction to handle the [Client Credentials Flow][client-cred-flow] as
defined in [OAuth 2.0][oauth2]. This is intended to support users who want to [configure an OpenFGA
server to use OIDC authentication](https://openfga.dev/docs/getting-started/setup-openfga/configure-openfga#oidc).

##### Client Credentials Flow

###### CredentialsFlowRequest

A request for an access token to an OAuth2 server should serialize into the
following JSON request:

```
{
    "client_id": "string",
    "client_secret": "string",
    "audience": "string",
    "grant_type": "string",
}
```

###### CredentialsFlowResponse

A successful response from an OAuth2 server must deserialize from the
following JSON shape:

```
{
    "access_token": "string",
    "scope": "string",
    "expires_in": "number",
    "token_type": "string",
}
```

The `access_token` property should be sent in HTTP headers set like so:

`Authorization: Bearer {{access_token}}`

With Python as an example, if `headers` is a dictionary, and `access_token` is
an access token from a `CredentialsFlowResponse`, then

```python
headers['Authorization'] = f'Bearer {access_token}'
```

#### Credentials

In most languages, Credentials should contain the following:

* [`CredentialsMethod`](#credentialsmethod) `credentialsMethod`
* [`ApiToken`](#apitoken) `apiToken` (optional/nullable)
* [`ClientCredentials`](#clientcredentials) `clientCredentials` (optional/nullable)

Credentials should also provide an `isValid()` function with the following check:

* When `credentialsMethod` is `NONE`, the credentials are valid.
* When `credentialsMethod` is `API_TOKEN`, the `apiToken` must be set.
* When `credentialsMethod` is `CLIENT_CREDENTIALS`, the `clientCredentials` must be set.

> Note: In languages that support tagged unions or algebraic data types, Credentials should be
> implemented as a mutually exclusive set of:
>
> * NONE
> * ApiToken `apiToken`
> * ClientCredentials `clientCredentials`
>
> These languages do not need to implement the `isValid()` function, as there is nothing to validate.

##### CredentialsMethod

CredentialsMethod should be modeled as a set of mutually-exclusive values. In most languages
this will be an "Enum" type. It should have the following values:

* `NONE`, which corresponds to credential-less HTTP requests
* `API_TOKEN`, which corresponds to an [`ApiToken`](#apitoken)
* `CLIENT_CREDENTIALS`, which corresponds to a [`ClientCredentials`](#clientcredentials)

##### ApiToken

ApiToken is a static API token. In [OAuth 2.0][oauth2] terms, this indicates an "access token"
that will be used to authenticate a request. In OpenFGA this can correspond to
[Pre-shared Key Authentication](https://openfga.dev/docs/getting-started/setup-openfga/configure-openfga#pre-shared-key-authentication).

ApiToken should contain:

* String `token`

##### ClientCredentials

ClientCredentials is a Client ID and Client Secret that can be exchanged with an [OAuth 2.0][oauth2]
server. This corresponds to a [Client Credentials Flow][client-cred-flow] to authenticate and
authorize a call to an OpenFGA server.

ClientCredentials should contain:

* String `clientId`
* String `clientSecret`
* String `apiTokenIssuer`
* String `apiAudience`

ClientCredentials should be only static data, and will not be concerned with performing network
calls or retrieving an access token. ClientCredentials will be resolved as part of
[Authentication](#authentication).

## High-level client

The "High-level client" is a more ergnomic client that provides a simpler abstraction than the
"[Low-level client](#low-level-client)." The naming convention is to call this High-level client
something like `OpenFgaClient`.

The High-level client should take a [`ClientConfiguration`](#clientconfiguration) that provides default
values like `storeId` and `authorizationModelId` that can be used for all operations.

It should also implement the following convenience functions:

* `setStoreId(String storeId)` -- sets the `storeId` for all subsequent operations that take a
  `storeId` as input.
* `setAuthorizationModelId(String authorizationModelId)` -- sets the `authorizationModelId` for all
  subsequent operations that take an `authorizationModelId` as input.
* `setConfiguration(ClientConfiguration configuration)` -- sets the `ClientConfiguration` for all
  subsequent operations.

### Implementation strategy

The High-level client should implement all OpenFGA operations, and additionally implement:

* [BatchCheck](#batchcheck)
* [ListRelations](#listrelations)
* [Non-transactional Write](#non-transactional-write)

All operations should take at most two inputs:

* A "Request"
  * This contains all non-pagination inputs to the equivalent [low-level client](#low-level-client)'s
    operations, minus a `storeId` or `authorizationModelId`. If the low-level operation takes those parameters, they should come from either the High-level client's `ClientConfiguration` or from an
    "Options" as described below.
  * `ListStores` has no request inputs
* An "Options." The Options itself is not required, and none of its fields are required. The Options
  will contain:
  * Additional HTTP headers to apply to the underlying request. These can be supplied to the low-level
    operation as part of a [ConfigurationOverride](#per-request-override).
  * If applicable, `storeId` and/or an `authorizationModelId`
  * If applicable, pagination properties of `pageSize` and/or `continuationToken`
  * For operations that perform parallel dispatch, `maxParallelRequests`. The operations that perform
    parallel dispatch are [BatchCheck](#batchcheck), [ListRelations](#listrelations), and
    [Non-transactional Write](#non-transactional-write).
    > Note: In this context, "parallel" means multiple requests are in flight at the same time. The
    > implementation in the language should handle the HTTP request dispatch in some reasonable and
    > idiomatic way. (This may mean promises, futures, async/await, etc.)

Likewise all operations should produce an output:

* A "Response"
  * Contains all properties of the low-level equivalent operation
  * Contains a reference to the initiating request
  * Contains the underlying HTTP `statusCode`
  * Contains the underlying HTTP `responseHeaders`
  * Contains the underlying HTTP `rawResponse`

### Client-side APIs

#### BatchCheck

The BatchCheck operation is a client-side API for issuing many Check operations at the same time.

BatchCheck should take a required List of ClientCheckRequest, and a non-required ClientBatchCheckOptions.
The ClientCheckRequest is expected to be the same type as used for the Check operation.

BatchCheck should dispatch the List of ClientCheckRequest as individual Check operations with the
following settings and behavior.

BatchCheck should set the following headers for all individual Check operations performed:

| Header                             | Value                                                 |
|------------------------------------|-------------------------------------------------------|
| `X-OpenFGA-Client-Method`          | `BatchCheck`                                          |
| `X-OpenFGA-Client-Bulk-Request-Id` | A single UUID shared for all batches of the operation |

ClientBatchCheckOptions should have a `maxParallelRequests` value, and the BatchCheck operation
should restrict the number of individual Check operations in flight to this number.

Note: The order of `BatchCheck` results is not guaranteed to match the order of the checks provided. Use `correlationId` to pair responses with requests.

BatchCheck should return a future/promise/async of a List of ClientBatchCheckResponse.

#### ListRelations

The ListRelations operation is a client-side API for listing the relations a user has with an
object (evaluates).

ListRelations should take a required ClientListRelationsRequest, and a non-required 
ClientListRelationsOptions. The ClientListRelationsRequest is expected to contain:

* String `user`
* String `object`
* List of String `relations`
* List of ClientTupleKey `contextualTupleKeys`

ListRelations will construct a List of ClientCheckRequest. The List will be of the same length
as `relations` and include the `user` and `object` inputs from the ClientListRelationsRequest.
ListRelations then dispatches the List of ClientCheckRequest to `BatchCheck`. The results of
`BatchCheck` should then be reduced down to only the List of String `relations` allowed, and
returned as part of a ClientListRelationsResponse.

ListRelations should set the following headers for all individual Check operations performed:

| Header                             | Value                                                 |
|------------------------------------|-------------------------------------------------------|
| `X-OpenFGA-Client-Method`          | `ListRelations`                                       |
| `X-OpenFGA-Client-Bulk-Request-Id` | A single UUID shared for all batches of the operation |

> Note: This means BatchCheck must not overwrite these headers.

ClientListRelationsOptions should have a `maxParallelRequests` value, and the ListRelations
operation should restrict the number of individual Check operations in flight to this number.
By reusing `BatchCheck` this should already be solved.

ListRelations should return a future/promise/async of a ClientListRelationsResponse that contains
a List of String `relations`.

#### Non-transactional Write

The high-level client's Write operation should call the low-level client's Write operation in two
modes:

* **Transaction mode:** A single high-level ClientWriteRequest will be dispatched as a single
  low-level client Write operation. In other words, it will be handled as a single "transaction."
  The ClientWriteRequest may contain multiple relationship tuple writes and deletes.
* **Non-transaction mode:** A single high-level ClientWriteRequest will be be dispatched as
  multiple smaller client Write operations. In other words, it will be handled as multiple
  "transactions." If a single transaction fails (with retries) then the Write operation should
  halt and return an appropriate error for the failing transaction.

Write should take a required ClientWriteRequest, and a non-required ClientWriteOptions. The ClientWriteRequest is expected to contain properties similar to the low-level WriteRequest.

Write in non-transaction mode should set the following headers for all individual Write operations
performed:

| Header                             | Value                                                 |
|------------------------------------|-------------------------------------------------------|
| `X-OpenFGA-Client-Method`          | `Write`                                               |
| `X-OpenFGA-Client-Bulk-Request-Id` | A single UUID shared for all batches of the operation |

> Note: This means Write in transaction mode should not overwrite these headers.

ClientWriteOptions should have a `disableTransactions` boolean property. When disabled, the Write
should be performed in non-transaction mode (as described above) and dispatch multiple smaller Write
operations. ClientWriteOptions should also have a `transactionChunkSize` postive integer value that
determines the maximum number of writes and/or deletes in a given transaction. The `transactionChunkSize`
should default to 1 if unset, and should only be respected when `disableTransactions` is set to true.

Write should return a future/promise/async of a ClientWriteResponse that contains only the HTTP details
of `statusCode`, `headers`, and the `rawResponse`. When run in non-transaction mode, this should be the
value of the final request issued.

## Retry

The following section defines the default retry behavior of all HTTP requests initiated by the
low-level client, the high-level client, and the [OAuth 2.0 client](#oauth2client).

These clients should respect the `maxRetries` property of a [Configuration](#configuration-1). The
default value of `maxRetries` should be sourced from mustache as `{{ defaultMaxRetry }}` which is
defined in `config/common/config.base.json`.

> Note: For the user of an SDK to opt-out of retries entirely, they should set `maxRetries` to `0`.

A retry should wait at least the value (sourced from mustahce) as `{{ defaultMinWaitInMs }}` which
is defined in `config/common/config.base.json`.

Retries should be performed for any HTTP 429 response, which indicates the server is throttling the
request. Retries should also be performed for any HTTP 5XX response, which indicates the server is
degraded for some reason.

## Errors

An OpenFGA SDK should define the following errors:

* `FgaInvalidParameterError` is raised when an operation was called with an invalid parameter. This
  is for early validation performed before dispatching any HTTP requests.
* `FgaApiAuthenticationError` is raised when an HTTP 401 (Unauthorized) or HTTP 403 (Forbidden)
  status code is encountered.
* `FgaApiInternalError` is raised when an HTTP 5XX status code is encountered.
* `FgaApiNotFoundError` is raised when an HTTP 404 (Not Found) status code is encountered.
* `FgaApiRateLimitExceededError` is raised when an HTTP 429 (Too Many Requests) status code is
  encountered, and the `maxRetries` have been exhausted.
* `FgaApiValidationError` is raised when an HTTP 400 (Bad Request) or HTTP 422 (Unprocessable Entity)
  is encountered. This most likely indicates either an issue in the serialization of the SDK, or that
  the SDK version and the OpenFGA server are operating at versions that are incompatible and have
  request/response shapes that differ.

Follow the naming conventions of your language when it comes to exceptions, errors, faults, etc.

## Documentation

### README files

The SDK repository's README is constructed from several partial README mustache templates as
described in [Manually adding a new SDK](#manually).

There is also a `docs/` directory that will be generated in the SDK repository with low-level
client objects.

In general, these should be simply checked for any errors, like URLs that point to the wrong place.

Once the high-level client is completed, the `README_initializing.mustache` and
`README_calling_api.mustache` should be written with examples of constructing the high-level client
and performing operations with an OpenFGA server.

### Language-specific docs

If your language ecosystem has a standardized place for documentation, this should also be generated
and included in the SDK's published assets. Examples include https://pkg.go.dev for Go modules,
https://javadoc.io for JVM-language JARs, or https://docs.rs for Rust crates.

### OpenFGA website docs

The OpenFGA website (https://openfga.dev) source code is located at the following github repository:

* https://github.com/openfga/openfga.dev

PRs should only be sent to this project after the high-level client is complete and the SDK
reasonably complies with this "Generating a new SDK" specification.



[client-cred-flow]: https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow
[oauth2]: https://oauth.net/2/
