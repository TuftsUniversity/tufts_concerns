require 'spec_helper'

describe TuftsVotingRecord do
  it 'has methods to support a draft version of the object'

  its(:human_readable_type) do
    expect(is_expected.to eq 'Voting Record')
  end

  its(:valid_child_concerns) do
    expect(is_expected.to eq [])
  end

  describe "#has_model" do
    let(:record) { TuftsVotingRecord.new(title: ['some title']) }
    subject { record.has_model }
    it { is_expected.to eq ['TuftsVotingRecord'] }
  end
end
