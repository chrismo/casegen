# frozen_string_literal: true

RSpec.describe CaseGen::ExcludeRule do
  it 'removes expect if excluded inline' do
    combo = CaseGen::Combination.new([{a: 1}, {b: :expect}])
    rule = described_class.new({criteria: 'a == 1', note: 'nope'}, [:exclude_inline])
    rule.apply([combo])
    expect(combo.hash_row).to eq({a: 1, b: '', exclude: 'nope'})
  end
end
