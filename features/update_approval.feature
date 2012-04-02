Feature: Update Approvals
    In order to provide an approval queue for new records

    Background:
        Given a record created with update approval

    Scenario: a new record is created
        Then it should have no pending changes

    Scenario: a record update should not change approvable fields
        When I update the record with:
            | title | updated     |
            | body  | not updated |
        Then it should have pending changes
        And the record should not have changed
        And the approval should have the changes

    Scenario: a record with pending changes should apply them after approval
        When I update the record with:
            | title | updated     |
            | body  | not updated |
        And I approve the changes
        Then it should have no pending changes
        And the record should have changed

    Scenario: a record with a large body of text should not break the system
        When I update the record with:
            | body | file:large |
        And I approve the changes
        When I update the record with:
            | body | file:second_large |
        And I approve the changes
        And the record should have changed to:
            | body | file:second_large |

    Scenario: a stale record is approved
        When I update the record with:
            | body | not updated |
        And the record is stale
        And I approve the changes
        Then it should raise ActsAsApprovable::Error::Stale

    Scenario: a stale record is forcefully approved
        When I update the record with:
            | body | not updated |
        And the record is stale
        And I approve the changes forcefully
        Then the record should have the changes
