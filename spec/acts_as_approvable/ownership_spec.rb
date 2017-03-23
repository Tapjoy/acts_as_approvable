require 'spec_helper'

describe ActsAsApprovable::Ownership do
  describe '.configure' do
    it 'defaults to Approval as the approval model' do
      expect(Approval).to receive(:include).with(ActsAsApprovable::Ownership)
      subject.configure
    end

    it 'defaults to User as the owner model' do
      expect(ActsAsApprovable).to receive(:owner_class=).with(User)
      subject.configure
    end

    it 'adds a belongs_to(:owner) association' do
      subject.configure
      expect(Approval.new).to belong_to(:owner)
    end

    it 'uses the given approval :model' do
      class FakeApproval < ActiveRecord::Base; end
      expect(FakeApproval).to receive(:include).with(ActsAsApprovable::Ownership)
      subject.configure(:model => FakeApproval)
    end

    it 'uses the given :owner' do
      class FakeUser; end
      expect(ActsAsApprovable).to receive(:owner_class=).with(FakeUser)
      subject.configure(:owner => FakeUser)
    end

    it 'uses the given :source' do
      class FakeSource; end
      expect(ActsAsApprovable).to receive(:owner_source=).with(FakeSource)
      subject.configure(:source => FakeSource)
    end
  end

  describe '.included' do
    before(:all) do
      class IncludedOwnership; include ActsAsApprovable::Ownership; end
    end

    it 'should extend ClassMethods' do
      expect(IncludedOwnership).to extend(ActsAsApprovable::Ownership::ClassMethods)
    end

    it 'should extend InstanceMethods' do
      expect(IncludedOwnership).to extend(ActsAsApprovable::Ownership::InstanceMethods)
    end
  end
end
