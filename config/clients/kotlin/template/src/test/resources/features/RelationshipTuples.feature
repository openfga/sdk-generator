Feature: Relationship Tuples
  As a user
  I want to be able to retrieve and modify relationship tuples for a store
  So that I can manage the relationships for my store

  Scenario: Get list of tuple changes
    Given the client has a valid API token
    And the server has authentication enabled
    When a GET request is made to the /stores/{store_id}/changes endpoint with a valid store id
    Then a 200 status code is returned
    And the response includes a list of tuple changes for the store

  Scenario: Query for all objects in a type definition
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/read endpoint with a valid store id and the following payload:
      | tuple_key                                                 |
      | {"user": "user:bob", "relation": "reader", "object": "document:"} |
    Then a 200 status code is returned
    And the response includes the matching tuples and an optional continuation token

  Scenario: Query for all stored relationship tuples that have a particular relation and object
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/read endpoint with a valid store id and the following payload:
      | tuple_key                                                |
      | {"object": "document:2021-budget", "relation": "reader"} |
    Then a 200 status code is returned
    And the response includes the matching tuples and an optional continuation token

  Scenario: Query for all users with all relationships for a particular document
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/read endpoint with a valid store id and the following payload:
  | tuple_key |
  | {"object": "document:2021-budget"} |
    Then a 200 status code is returned
    And the response includes the matching tuples and an optional continuation token

  Scenario: Add or delete tuples from the store
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/write endpoint with a valid store id and the following payload:
      | tuples |
      | [{"key": {"user": "user:anne", "relation": "writer", "object": "document:2021-budget"}}] |
    Then a 200 status code is returned
    And the tuples are added or deleted from the store
