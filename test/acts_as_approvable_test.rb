require 'test_helper'

class ActsAsApprovableTest < Test::Unit::TestCase
  should 'set VERSION contanst to file contents' do
    contents = File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'VERSION'))).chomp
    assert_equal ActsAsApprovable::VERSION, contents
  end
end
