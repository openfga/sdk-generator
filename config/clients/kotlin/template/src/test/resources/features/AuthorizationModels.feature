Feature: Authorization Models
  As a user
  I want to be able to retrieve and create authorization models for a store
  So that I can manage the authorization models for my store

  Scenario: Get authorization models for a store
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores/{store_id}/authorization-models endpoint with a valid store id
    Then a 200 status code is returned
    And the response includes the authorization models for the store

  Scenario: Create a new authorization model
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/authorization-models endpoint with a valid store id and a type definitions object in the request body
    Then a 201 status code is returned
    And the response includes the newly created authorization model

  Scenario: Get a specific authorization model
    Given the client has a valid API token
    And the server has authentication enabled
    And an authorization model exists for a store
    When a GET request is made to the /stores/{store_id}/authorization-models/{id} endpoint with a valid store id and authorization model id
    Then a 200 status code is returned
    And the response includes the authorization model

  Scenario: Get authorization models for a store - Invalid store id
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores/{store_id}/authorization-models endpoint with an invalid store id
    Then a 400 status code is returned
    And the response includes an error message

  Scenario: Create a new authorization model - Invalid store id
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/authorization-models endpoint with an invalid store id and a type definitions object in the request body
    Then a 400 status code is returned
    And the response includes an error message

  Scenario: Get a specific authorization model - Invalid store id
    Given the client has a valid API token
    And the server has authentication enabled
    And an authorization model exists for a store
    When a GET request is made to the /stores/{store_id}/authorization-models/{id} endpoint with an invalid store id and valid authorization model id
    Then a 404 status code is returned
    And the response includes an error message

  Scenario: Get a specific authorization model - Invalid authorization model id
    Given the client has a valid API token
    And the server has authentication enabled
    And an authorization model exists for a store
    When a GET request is made to the /stores/{store_id}/authorization-models/{id} endpoint with a valid store id and invalid authorization model id
    Then a 404 status code is returned
    And the response includes an error message

  Scenario: Server error
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores/{store_id}/authorization-models endpoint with a valid store id
    Then a 500 status code is returned
    And the response includes an error message