Feature: Relationship Queries
  Scenario: Check for a certain relationship
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/check endpoint with a valid store id and the following payload:
      | tuple_key                         | contextual_tuples                                                                                               |
      | {"user": "user:anne", "relation": "reader", "object": "document:2021-budget"} | {"tuple_keys": [{"user": "user:anne", "relation": "member", "object": "time_slot:office_hours"}]} |
    Then a 200 status code is returned
    And the response includes a field "allowed" indicating whether the relationship exists

  Scenario: Expand all users with certain relationship with an object
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/expand endpoint with a valid store id and the following payload:
      | tuple_key                         |
      | {"object": "document:2021-budget", "relation": "reader"} |
    Then a 200 status code is returned
    And the response includes a tree of users and usersets with the specified relationship

  Scenario: List objects with a certain relationship
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/list-objects endpoint with a valid store id and the following payload:
      | tuple_key                         | contextual_tuples |
      | {"user": "user:anne", "relation": "reader"} | [] |
    Then a 200 status code is returned
    And the response includes a list of related objects in the "objects" field

  Scenario: Streamed list objects with a certain relationship
    Given the client has a valid API token
    And the server has authentication enabled
    When a POST request is made to the /stores/{store_id}/streamed-list-objects endpoint with a valid store id and the following payload:
      | tuple_key                         | contextual_tuples |
      | {"user": "user:anne", "relation": "reader"} | [] |
    Then a 200 status code is returned
    And the response includes a streamed list of related objects

