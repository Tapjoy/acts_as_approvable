require 'spec_helper'

describe ActsAsApprovable do
  it { should respond_to(:owner_class) }
  it { should respond_to(:owner_class=) }
  it { should respond_to(:view_language) }
  it { should respond_to(:view_language=) }

  describe '.enabled?' do
    it 'returns true by default' do
      subject.enabled?.should be_true
    end
  end

  describe '.disable' do
    it 'disables the approval queue' do
      subject.disable
      subject.enabled?.should be_false
    end
  end

  describe '.enable' do
    it 'enables the approval queue' do
      subject.enable
      subject.enabled?.should be_true
    end
  end

end
