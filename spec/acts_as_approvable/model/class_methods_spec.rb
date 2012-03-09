require 'spec_helper'

describe ActsAsApprovable::Model::ClassMethods do
  subject { DefaultApprovable }

  describe '.acts_as_approvable' do
    subject { CleanApprovable }

    it 'includes InstanceMethods into the class' do
      subject.should_not extend(ActsAsApprovable::Model::InstanceMethods)
      subject.acts_as_approvable
      subject.should extend(ActsAsApprovable::Model::InstanceMethods)
    end

    it 'includes ClassMethods into the class' do
      subject.should_not extend(ActsAsApprovable::Model::ClassMethods)
      subject.acts_as_approvable
      subject.should extend(ActsAsApprovable::Model::ClassMethods)
    end
  end

  describe '.approvals_enabled?' do
    before(:each) do
      subject.stub(:global_approvals_on? => true)
      subject.stub(:approvals_on? => true)
    end

    context 'when approvals are globally disabled' do
      before(:each) do
        subject.stub(:global_approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the model status' do
        subject.should_not_receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Model' do
      before(:each) do
        subject.stub(:approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        subject.should_receive(:approvals_on?).and_return(false)
        subject.approvals_enabled?
      end
    end
  end

  describe '.approvals_disabled?' do
    before(:each) do
      subject.stub(:approvals_enabled? => true)
    end

    it 'returns the inverse of the approval queue status' do
      subject.approvals_disabled?.should == !subject.approvals_enabled?
    end

    it 'calls .approvals_enabled? for the status' do
      subject.should_receive(:approvals_enabled?).and_return(true)
      subject.approvals_disabled?
    end
  end

  describe '.approvals_off' do
    before(:each) do
      subject.approvals_off
    end

    it 'disables the model level approval queue' do
      subject.approvals_on?.should be_false
    end
  end

  describe '.approvals_on' do
    before(:each) do
      subject.approvals_on
    end

    it 'enables the model level approval queue' do
      subject.approvals_on?.should be_true
    end
  end

  describe '.approvals_on?' do
    context 'when approval queues are enabled locally' do
      before(:each) do
        subject.approvals_disabled = false
      end

      it 'returns true' do
        subject.approvals_on?.should be_true
      end

      it 'ignores the global level status' do
        subject.stub(:global_approvals_on? => false)
        subject.approvals_on?.should be_true
      end
    end

    context 'when approval queues are disabled locally' do
      before(:each) do
        subject.approvals_disabled = true
      end

      it 'returns false' do
        subject.approvals_on?.should be_false
      end

      it 'ignores the global level status' do
        subject.stub(:global_approvals_on? => true)
        subject.approvals_on?.should be_false
      end
    end
  end

  describe '.global_approvals_on?' do
    it 'checks the global approval status' do
      ActsAsApprovable.should_receive(:enabled?)
      subject.global_approvals_on?
    end
  end

  describe '.approvable_on?' do
    it { should be_approvable_on(:create) }
    it { should be_approvable_on(:update) }

    context 'when the model is approvable on :create events' do
      subject { CreatesApprovable }

      it { should be_approvable_on(:create) }
      it { should_not be_approvable_on(:update) }
    end

    context 'when the model is approvable on :update events' do
      subject { UpdatesApprovable }

      it { should be_approvable_on(:update) }
      it { should_not be_approvable_on(:create) }
    end
  end

  describe '.approvable_fields' do
    subject { CleanApprovable }

    context 'with :only fields configured' do
      before(:each) do
        subject.acts_as_approvable :only => [:body, :extra]
      end

      it 'returns the configured fields' do
        subject.approvable_fields.should == ['body', 'extra']
      end
    end

    context 'with :ignore fields configured' do
      before(:each) do
        subject.acts_as_approvable :ignore => [:title, :extra]
      end

      it 'returns the available fields minus whats ignored' do
        subject.approvable_fields.should include('body')
      end

      it 'ignores timestamps' do
        subject.approvable_fields.should_not include('created_at')
        subject.approvable_fields.should_not include('updated_at')
      end

      it 'ignores primary keys' do
        subject.approvable_fields.should_not include(subject.primary_key)
      end
    end
  end

  describe '.without_approval' do
    around(:each) do |example|
      subject.approvals_on
      example.run
      subject.approvals_on
    end

    it 'disables approval queues' do
      @record = subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      @record.approval.should_not be
    end

    it 'enables the approval queue after running' do
      subject.should be_approvals_on
      subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      subject.should be_approvals_on
    end

    it 'returns the approval queue to the previous state' do
      subject.approvals_off
      subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      subject.should_not be_approvals_on
    end
  end
end
