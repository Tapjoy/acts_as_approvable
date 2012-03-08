require 'spec_helper'

describe ActsAsApprovable::Model::InstanceMethods do
  subject { DefaultApprovable.new }

  describe '#approvals_enabled?' do
    before(:each) do
        subject.stub(:global_approvals_on? => true)
        subject.stub(:model_approvals_on? => true)
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
        subject.should_not_receive(:model_approvals_on?)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        subject.should_not_receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Model' do
      before(:each) do
        subject.stub(:model_approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        subject.should_receive(:model_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        subject.should_not_receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Record' do
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
        subject.should_receive(:model_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the record status' do
        subject.should_receive(:approvals_on?).and_return(false)
        subject.approvals_enabled?
      end
    end
  end

  describe '#approvals_disabled?' do
    before(:each) do
      subject.stub(:approvals_enabled? => true)
    end

    it 'returns the inverse of #approvals_enabled?' do
      subject.approvals_disabled?.should == !subject.approvals_enabled?
    end

    it 'calls #approvals_enabled?' do
      subject.should_receive(:approvals_enabled?).and_return(true)
      subject.approvals_disabled?
    end
  end

  describe '#approvals_off' do
    before(:each) do
      subject.approvals_off
    end

    it 'disables the record level approval queue' do
      subject.approvals_on?.should be_false
    end
  end

  describe '#approvals_on' do
    before(:each) do
      subject.approvals_on
    end

    it 'enables the record level approval queue' do
      subject.approvals_on?.should be_true
    end
  end
end
