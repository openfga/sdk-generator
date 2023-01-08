Feature: Assertions
  Scenario: Read assertions for authorization model
    Given I have a valid authorization model
    When I make a request to read an assertion
    Then I receive a response with a status code 200
    And the response body contains the assertions for the authorization model.

  Scenario: Write assertions for authorization model
    Given I have an authorization model with an ID "01G5JAVJ41T49E9TT3SKVS7X1J"
    And I have a valid assertion object
    When I create an assertion using the assertion endpoint
    Then I receive a response with a status code 200
    And the response body contains the assertions for the authorization model.