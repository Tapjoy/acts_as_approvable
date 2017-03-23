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
      expect(subject.destroy_approvals).to eq([@approval1, @approval2])
    end

    context 'when requesting only pending records' do
      it 'retreives pending :destroy approvals' do
        expect(subject.destroy_approvals(false)).to eq([@approval2])
      end
    end

    context 'with other event records' do
      subject { DefaultApprovable.create }

      before(:each) do
        @approval3 = subject.approval

        subject.update_attribute(:title, 'review')
        @approval4 = subject.approvals.last
        @approval4.approve!
      end

      it 'retreives only :destroy approvals' do
        expect(subject.destroy_approvals).to eq([@approval1, @approval2])
      end

      context 'when requesting only pending records' do
        it 'retreives only pending :destroy approvals' do
          expect(subject.destroy_approvals(false)).to eq([@approval2])
        end
      end
    end
  end

  describe '#pending_destruction?' do
    context 'with pending approvals' do
      it { is_expected.not_to be_pending_destruction }
    end

    context 'with pending approvals' do
      before(:each) do
        subject.destroy
      end

      it { is_expected.to be_pending_destruction }
    end

    context 'with rejected approvals' do
      before(:each) do
        subject.destroy
        subject.approvals.last.reject!
      end

      it { is_expected.not_to be_pending_destruction }
    end
  end
end
