require 'test_helper'

class ActsAsApprovableSchemaTest < Test::Unit::TestCase
  def setup
    load_schema
  end

  def test_schema_has_loaded_correctly
    assert_equal [], User.all
    assert_equal [], Project.all
    assert_equal [], Approval.all
  end
end
