Feature: Stores Endpoint
  As a user
  I want to be able to create, read, and delete stores
  So that I can manage my store information

  Scenario: Create a new store
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores endpoint with the following payload:
      | name  |
      | Store1 |
    Then a 201 status code is returned
    And the response includes the newly created store information

  Scenario: Get a list of stores
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores endpoint
    Then a 200 status code is returned
    And the response includes a list of stores

  Scenario: Get a single store
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores/{id} endpoint with a valid store id
    Then a 200 status code is returned
    And the response includes the store information

  Scenario: Delete a store
    Given the client has a valid API token
    And the server has authentication enabled
    And a store exists with the following information:
      | name  |
      | Store1 |
    When a DELETE request is made to the /stores/{id} endpoint with a valid store id
    Then a 200 status code is returned
    And the store is no longer returned in a GET request to the /stores endpoint