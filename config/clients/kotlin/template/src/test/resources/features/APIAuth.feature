Feature: OpenFGA Client API Authentication
  Scenario: No Auth Request against No Auth Server
    Given the client has authentication disabled
    And the server has authentication disabled
    When a request is made to the server
    Then a valid response is received

  Scenario: No Auth Request against Auth Server
    Given the client has authentication disabled
    And the server has authentication enabled
    When a request is made to the server
    Then an invalid response is received

  Scenario: API Token against API Token Enabled Server
    Given the client has a valid API token
    And the server has authentication enabled
    When a request is made to the server with the API token
    Then a valid response is received
    And the authorization header includes the bearer token

  Scenario: Invalid API Token
    Given the client has an invalid API token
    When a request is made to the server with the invalid API token
    Then an API value exception is raised

  Scenario: Client Credentials against Client Credential Server
    Given the client has valid client credentials with a valid configuration
    And the server has authentication enabled
    When a request is made to the server with the client credentials
    Then a valid response is received
    And the authorization header includes the bearer token

  Scenario: Empty API Token
    Given the client is using API token credentials with an empty API token
    When a request is made to the server with the empty API token
    Then an API value exception is raised

  Scenario: Client Credentials with Empty API Client ID
    Given the client has API token credentials with an empty client ID field
    When a request is made to the server with the API token credentials
    Then an API value exception is raised

  Scenario: Client Credentials with Empty API Client Secret
    Given the client has API token credentials with an empty client secret field
    When a request is made to the server with the API token credentials
    Then an API value exception is raised

  Scenario: Client Credentials with Empty API Issuer
    Given the client has API token credentials with an empty issuer field
    When a request is made to the server with the API token credentials
    Then an API value exception is raised

  Scenario: Client Credentials with Empty API Audience
    Given the client has API token credentials with an empty audience field
    When a request is made to the server with the API token credentials
    Then an API value exception is raised