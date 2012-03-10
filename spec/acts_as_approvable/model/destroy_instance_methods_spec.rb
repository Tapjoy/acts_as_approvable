require 'spec_helper'

describe ActsAsApprovable::Model::DestroyInstanceMethods do
  subject { DestroysApprovable.create }

  describe '#destroy_approvals' do
    before(:each) do
      subject.destroy
      @approval1 = subject.approvals.last
      @approval1.reject!

      subject.destroy
      @approval2 = subject.approvals.last
    end

    it 'retreives all :destroy approvals' do
      subject.destroy_approvals.should == [@approval1, @approval2]
    end

    context 'when requesting only pending records' do
      it 'retreives pending :destroy approvals' do
        subject.destroy_approvals(false).should == [@approval2]
      end
    end
  end

  describe '#pending_destruction?' do
    context 'with pending approvals' do
      it { should_not be_pending_destruction }
    end

    context 'with pending approvals' do
      before(:each) do
        subject.destroy
      end

      it { should be_pending_destruction }
    end

    context 'with rejected approvals' do
      before(:each) do
        subject.destroy
        subject.approvals.last.reject!
      end

      it { should_not be_pending_destruction }
    end
  end
end
