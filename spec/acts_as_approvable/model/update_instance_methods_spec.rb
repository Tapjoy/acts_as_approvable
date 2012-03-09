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
      subject.update_approvals.should == [@approval1, @approval2]
    end

    context 'when requesting only pending records' do
      it 'retreives pending :update approvals' do
        subject.update_approvals(false).should == [@approval2]
      end
    end
  end

  describe '#pending_changes?' do
    it 'returns false with no pending approvals' do
      subject.should_not be_pending_changes
    end

    context 'with pending approvals' do
      before(:each) do
        subject.update_attributes(:title => 'review')
      end

      it 'returns true' do
        subject.should be_pending_changes
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
        subject.should_not be_pending_changes
      end
    end
  end

  describe '#changed_notably?' do
    it 'returns true if #notably_changed returns values' do
      subject.stub(:notably_changed => [1])
      subject.should be_changed_notably
    end

    it 'returns false if #notably_changed does not return values' do
      subject.stub(:notably_changed => [])
      subject.should_not be_changed_notably
    end
  end

  describe '#notably_changed' do
    before(:each) do
      subject.title = 'review'
      subject.updated_at += 60
    end

    it 'includes fields that should be approved' do
      subject.changed.should include('title')
      subject.notably_changed.should include('title')
    end

    it 'does not include fields that should be ignored' do
      subject.changed.should include('updated_at')
      subject.notably_changed.should_not include('updated_at')
    end

    it 'gets a list of approvable fields from #approvable_fields' do
      subject.should_receive(:approvable_fields).and_return([])
      subject.notably_changed
    end
  end

  describe '#approvable_fields' do
    it 'proxies to the class level' do
      subject.class.should_receive(:approvable_fields)
      subject.approvable_fields
    end
  end

  context 'when a record is updated' do
    before(:each) do
      subject.update_attribute(:body, 'updated')
    end

    it 'saves the updated values to the approval record' do
      subject.update_approvals.last.object.should == {'body' => 'updated'}
    end

    it 'saves the original values to the approval record' do
      subject.update_approvals.last.original.should == {'body' => nil}
    end
  end
end
