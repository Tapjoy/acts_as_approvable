require 'spec_helper'

describe ActsAsApprovable::Model do
  context 'with default configuration options' do
    subject { DefaultApprovable }

    it { should be_approvable_on(:create) }
    it { should be_approvable_on(:update) }
    it { should be_approvals_enabled }
    it { subject.new.should have_many(:approvals) }

    it { should extend(ActsAsApprovable::Model::InstanceMethods) }
    it { should extend(ActsAsApprovable::Model::CreateInstanceMethods) }
    it { should extend(ActsAsApprovable::Model::UpdateInstanceMethods) }

    it 'has no approvable_field' do
      subject.approvable_field.should_not be
    end

    it 'ignores timestamps' do
      subject.approvable_ignore.should include('created_at')
      subject.approvable_ignore.should include('updated_at')
    end

    it 'ignores the primary key' do
      subject.approvable_ignore.should include(subject.primary_key)
    end
  end

  context 'with :create as the only event' do
    context 'and no other options' do
      subject { CreatesApprovable }

      it { should be_approvable_on(:create) }
      it { should_not be_approvable_on(:update) }

      it { should extend(ActsAsApprovable::Model::InstanceMethods) }
      it { should extend(ActsAsApprovable::Model::CreateInstanceMethods) }
      it { should_not extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
    end

    context 'and a :state_field' do
      subject { CreatesWithStateApprovable }

      it 'has an approvable_field' do
        subject.approvable_field.should be
      end

      it 'ignores the approvable_field' do
        subject.approvable_ignore.should include(subject.approvable_field.to_s)
      end

      it 'ignores timestamps' do
        subject.approvable_ignore.should include('created_at')
        subject.approvable_ignore.should include('updated_at')
      end

      it 'ignores the primary key' do
        subject.approvable_ignore.should include(subject.primary_key)
      end
    end
  end

  context 'with :update as the only event' do
    context 'and no other options' do
      subject { UpdatesApprovable }

      it { should be_approvable_on(:update) }
      it { should_not be_approvable_on(:create) }

      it { should extend(ActsAsApprovable::Model::InstanceMethods) }
      it { should extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
      it { should_not extend(ActsAsApprovable::Model::CreateInstanceMethods) }
    end

    context 'and :only fields' do
      subject { UpdatesOnlyFieldsApprovable }

      describe '.approvable_fields' do
        subject { UpdatesOnlyFieldsApprovable.approvable_fields }

        it { should include('body') }
      end
    end

    context 'with :ignore fields' do
      subject { UpdatesIgnoreFieldsApprovable }

      it 'ignores the given fields' do
        subject.approvable_ignore.should include('title')
      end

      it 'ignores timestamps' do
        subject.approvable_ignore.should include('created_at')
        subject.approvable_ignore.should include('updated_at')
      end

      it 'ignores the primary key' do
        subject.approvable_ignore.should include(subject.primary_key)
      end

      describe '.approvable_fields' do
        subject { UpdatesIgnoreFieldsApprovable.approvable_fields }

        it { should include('body') }
      end
    end
  end
end
