Feature: Create Approvals
    In order to provide an approval queue for new records

    Background:
        Given a record created with create approval

    Scenario: a new record is created
        Then it should be pending

    Scenario: a new record is approved
        When I approve the record
        Then it should be approved

    Scenario: a new record is rejected
        When I reject the record
        Then it should be rejected

    Scenario: an approved record is approved again
        When the record is already approved
        And I approve the record
        Then it should raise ActsAsApprovable::Error::Locked

    Scenario: an approved record is rejected
        When the record is already approved
        And I reject the record
        Then it should raise ActsAsApprovable::Error::Locked
