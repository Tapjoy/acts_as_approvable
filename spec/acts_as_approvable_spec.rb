require 'spec_helper'

describe ActsAsApprovable do
  describe '.enable' do
    it 'flags the approval queue as on' do
      ActsAsApprovable.enable
      ActsAsApprovable.enabled?.should be_true
    end
  end
end
