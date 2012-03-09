require 'spec_helper'

describe ActsAsApprovable::Ownership::InstanceMethods do
  before(:all) do
    ActsAsApprovable::Ownership.configure
  end

  before(:each) do
    @user1 = User.create
    @user2 = User.new
    subject.stub(:save => true)
  end

  subject { Approval.new }

  describe '#assign' do
    it 'sets the owner' do
      expect { subject.assign(@user1) }.to change{subject.owner}.from(nil).to(@user1)
    end

    it 'raises an InvalidOwner error if the owner is not valid' do
      expect { subject.assign(@user2) }.to raise_error(ActsAsApprovable::Error::InvalidOwner)
    end
  end

  describe '#unassign' do
    it 'removes the assigned owner' do
      subject.owner = @user1
      expect { subject.unassign }.to change{subject.owner}.from(@user1).to(nil)
    end
  end
end
