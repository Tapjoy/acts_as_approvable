require 'spec_helper'

describe ActsAsApprovable do
  it { is_expected.to respond_to(:owner_class) }
  it { is_expected.to respond_to(:owner_class=) }
  it { is_expected.to respond_to(:view_language) }
  it { is_expected.to respond_to(:view_language=) }
  it { is_expected.to respond_to(:stale_check=) }
  it { is_expected.to respond_to(:stale_check?) }

  describe '.enabled?' do
    it 'returns true by default' do
      expect(subject.enabled?).to be_truthy
    end
  end

  describe '.disable' do
    it 'disables the approval queue' do
      subject.disable
      expect(subject.enabled?).to be_falsey
    end
  end

  describe '.enable' do
    it 'enables the approval queue' do
      subject.enable
      expect(subject.enabled?).to be_truthy
    end
  end

end
