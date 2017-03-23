require 'spec_helper'

describe ActsAsApprovable::Model::UpdateInstanceMethods do
  subject { UpdatesApprovable.create }

  describe '#update_approvals' do
    before(:each) do
      subject.update_attributes(:title => 'review')
      @approval1 = subject.approvals.last
      @approval1.approve!

      subject.update_attributes(:title => 'review2')
      @approval2 = subject.approvals.last
    end

    it 'retreives all :update approvals' do
      expect(subject.update_approvals).to eq([@approval1, @approval2])
    end

    context 'when requesting only pending records' do
      it 'retreives pending :update approvals' do
        expect(subject.update_approvals(false)).to eq([@approval2])
      end
    end
  end

  describe '#pending_changes?' do
    it 'returns false with no pending approvals' do
      expect(subject).not_to be_pending_changes
    end

    context 'with pending approvals' do
      before(:each) do
        subject.update_attributes(:title => 'review')
      end

      it 'returns true' do
        expect(subject).to be_pending_changes
      end
    end

    context 'with approved and rejected approvals' do
      before(:each) do
        subject.update_attributes(:title => 'review')
        subject.approvals.last.approve!

        subject.update_attributes(:title => 'review')
        subject.approvals.last.reject!
      end

      it 'returns false' do
        expect(subject).not_to be_pending_changes
      end
    end
  end

  describe '#changed_notably?' do
    it 'returns true if #notably_changed returns values' do
      allow(subject).to receive_messages(:notably_changed => [1])
      expect(subject).to be_changed_notably
    end

    it 'returns false if #notably_changed does not return values' do
      allow(subject).to receive_messages(:notably_changed => [])
      expect(subject).not_to be_changed_notably
    end
  end

  describe '#notably_changed' do
    before(:each) do
      subject.title = 'review'
      subject.updated_at += 60
    end

    it 'includes fields that should be approved' do
      expect(subject.changed).to include('title')
      expect(subject.notably_changed).to include('title')
    end

    it 'does not include fields that should be ignored' do
      expect(subject.changed).to include('updated_at')
      expect(subject.notably_changed).not_to include('updated_at')
    end

    it 'gets a list of approvable fields from #approvable_fields' do
      expect(subject).to receive(:approvable_fields).and_return([])
      subject.notably_changed
    end
  end

  describe '#approvable_fields' do
    it 'proxies to the class level' do
      expect(subject.class).to receive(:approvable_fields)
      subject.approvable_fields
    end
  end

  context 'when a record is updated' do
    before(:each) do
      subject.update_attribute(:body, 'updated')
    end

    it 'saves the updated values to the approval record' do
      expect(subject.update_approvals.last.object).to eq({'body' => 'updated'})
    end

    it 'saves the original values to the approval record' do
      expect(subject.update_approvals.last.original).to eq({'body' => nil})
    end
  end
end
