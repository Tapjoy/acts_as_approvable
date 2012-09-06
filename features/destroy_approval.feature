Feature: Create Approvals
  In order to provide an approval queue for destroying records

  Background:
    Given a record created with destroy approval

  Scenario: a 'destroyed' record should not actually destroy
    When I destroy the record
    Then it should be pending destruction

  Scenario: a 'destroyed' record should be destroyed after it is approved
    When I destroy the record
    And I approve the destruction
    Then it should no longer exist

  Scenario: a 'destroyed' record should not be destroyed after it is rejected
    When I destroy the record
    And I reject the destruction
    Then it should still exist
