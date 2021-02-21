# frozen_string_literal: true

require 'spec_helper'
require_relative '../doc/pricing.sample'

RSpec.describe 'Exclude inline with footnotes' do
  let(:expected_table) do
    <<~_
      +----------+----------+-------+--------+---------+
      | subtotal | discount | promo | total  | exclude |
      +----------+----------+-------+--------+---------+
      | 25       | 0%       | none  | 25.00  |         |
      | 25       | 0%       | apr   | 17.50  |         |
      | 25       | 0%       | fall  | 16.25  |         |
      | 25       | 10%      | none  |        | [2]     |
      | 25       | 10%      | apr   |        | [2]     |
      | 25       | 10%      | fall  |        | [2]     |
      | 25       | 20%      | none  |        | [1]     |
      | 25       | 20%      | apr   |        | [1]     |
      | 25       | 20%      | fall  |        | [1]     |
      | 75       | 0%       | none  |        | [4]     |
      | 75       | 0%       | apr   |        | [4]     |
      | 75       | 0%       | fall  |        | [4]     |
      | 75       | 10%      | none  | 67.50  |         |
      | 75       | 10%      | apr   | 47.25  |         |
      | 75       | 10%      | fall  | 43.88  |         |
      | 75       | 20%      | none  |        | [1]     |
      | 75       | 20%      | apr   |        | [1]     |
      | 75       | 20%      | fall  |        | [1]     |
      | 200      | 0%       | none  |        | [3]     |
      | 200      | 0%       | apr   |        | [3]     |
      | 200      | 0%       | fall  |        | [3]     |
      | 200      | 10%      | none  |        | [3]     |
      | 200      | 10%      | apr   |        | [3]     |
      | 200      | 10%      | fall  |        | [3]     |
      | 200      | 20%      | none  | 160.00 |         |
      | 200      | 20%      | apr   |        | [5]     |
      | 200      | 20%      | fall  |        | [5]     |
      +----------+----------+-------+--------+---------+

      exclude
      -------
      [1] Total must be above $100 to apply the 20% discount
      [2] Total must be above $50 to apply the 10% discount
      [3] Orders over 100 automatically get 20% discount
      [4] Orders between 50 and 100 automatically get 10% discount
      [5] 20% discount cannot be combined with promo
    _
  end

  let(:sets) { Fixtures[:pricing][:sets] }
  let(:rules) { Fixtures[:pricing][:rules] }

  it 'output' do
    result = CaseGen.generate(sets, rules, [:exclude_inline_footnotes])
    expect(result).to eq expected_table.chomp
  end
end
