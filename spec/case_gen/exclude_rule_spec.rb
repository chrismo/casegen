# frozen_string_literal: true

RSpec.describe CaseGen::ExcludeRule do
  it 'removes expect if excluded inline' do
    combo = CaseGen::Combination.new([{a: 1}, {b: :expect}])
    rule = described_class.new({criteria: 'a == 1', note: 'nope'})
    rule.apply([combo])
    expect(combo).to be_excluded
  end

  it 'marks combo as exclude on matching key/values in rule data' do
    combo = CaseGen::Combination.new([{a: 1}, {b: 2}])
    rule = described_class.new({b: 2, note: 'nope'})
    rule.apply([combo])
    expect(combo).to be_excluded
  end
end
