require 'spec_helper'

describe ActsAsApprovable::Ownership do
  describe '.configure' do
    it 'defaults to Approval as the approval model' do
      Approval.should_receive(:include).with(ActsAsApprovable::Ownership)
      subject.configure
    end

    it 'defaults to User as the owner model' do
      ActsAsApprovable.should_receive(:owner_class=).with(User)
      subject.configure
    end

    it 'adds a belongs_to(:owner) association' do
      subject.configure
      Approval.new.should belong_to(:owner)
    end

    it 'uses the given approval :model' do
      class FakeApproval < ActiveRecord::Base; end
      FakeApproval.should_receive(:include).with(ActsAsApprovable::Ownership)
      subject.configure(:model => FakeApproval)
    end

    it 'uses the given :owner' do
      class FakeUser; end
      ActsAsApprovable.should_receive(:owner_class=).with(FakeUser)
      subject.configure(:owner => FakeUser)
    end

    it 'applies the provided block' do
      Approval.should_receive(:class_exec)
      subject.configure {}
    end
  end

  describe '.included' do
    before(:all) do
      class IncludedOwnership; include ActsAsApprovable::Ownership; end
    end

    it 'should extend ClassMethods' do
      IncludedOwnership.should extend(ActsAsApprovable::Ownership::ClassMethods)
    end

    it 'should extend InstanceMethods' do
      IncludedOwnership.should extend(ActsAsApprovable::Ownership::InstanceMethods)
    end
  end
end
