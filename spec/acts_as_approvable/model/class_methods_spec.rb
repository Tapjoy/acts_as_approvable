require 'spec_helper'

describe ActsAsApprovable::Model::InstanceMethods do
  subject { NotApprovable }

  describe '.acts_as_approvable' do
    it 'includes InstanceMethods into the class' do
      subject.should_not extend(ActsAsApprovable::Model::InstanceMethods)
      subject.acts_as_approvable
      subject.should extend(ActsAsApprovable::Model::InstanceMethods)
    end
  end
end
