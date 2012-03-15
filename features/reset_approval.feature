Feature: Reset Approvals
    In order to allow reseting record creation approval for future-approval.

    Background:
        Given a record created with create approval
        And the record is stale

    Scenario: a stale record is encountered
        Then it should be stale

    Scenario: a stale record is reset
        When I reset the record
        Then it should not be stale
