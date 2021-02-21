# frozen_string_literal: true

require 'spec_helper'
require_relative '../doc/pricing.sample'

RSpec.describe 'Exclude inline' do
  let(:expected_table) do
    <<~_
      +----------+----------+-------+--------+----------------------------------------------------------+
      | subtotal | discount | promo | total  |                         exclude                          |
      +----------+----------+-------+--------+----------------------------------------------------------+
      | 25       | 0%       | none  | 25.00  |                                                          |
      | 25       | 0%       | apr   | 17.50  |                                                          |
      | 25       | 0%       | fall  | 16.25  |                                                          |
      | 25       | 10%      | none  |        | Total must be above $50 to apply the 10% discount        |
      | 25       | 10%      | apr   |        | Total must be above $50 to apply the 10% discount        |
      | 25       | 10%      | fall  |        | Total must be above $50 to apply the 10% discount        |
      | 25       | 20%      | none  |        | Total must be above $100 to apply the 20% discount       |
      | 25       | 20%      | apr   |        | Total must be above $100 to apply the 20% discount       |
      | 25       | 20%      | fall  |        | Total must be above $100 to apply the 20% discount       |
      | 75       | 0%       | none  |        | Orders between 50 and 100 automatically get 10% discount |
      | 75       | 0%       | apr   |        | Orders between 50 and 100 automatically get 10% discount |
      | 75       | 0%       | fall  |        | Orders between 50 and 100 automatically get 10% discount |
      | 75       | 10%      | none  | 67.50  |                                                          |
      | 75       | 10%      | apr   | 47.25  |                                                          |
      | 75       | 10%      | fall  | 43.88  |                                                          |
      | 75       | 20%      | none  |        | Total must be above $100 to apply the 20% discount       |
      | 75       | 20%      | apr   |        | Total must be above $100 to apply the 20% discount       |
      | 75       | 20%      | fall  |        | Total must be above $100 to apply the 20% discount       |
      | 200      | 0%       | none  |        | Orders over 100 automatically get 20% discount           |
      | 200      | 0%       | apr   |        | Orders over 100 automatically get 20% discount           |
      | 200      | 0%       | fall  |        | Orders over 100 automatically get 20% discount           |
      | 200      | 10%      | none  |        | Orders over 100 automatically get 20% discount           |
      | 200      | 10%      | apr   |        | Orders over 100 automatically get 20% discount           |
      | 200      | 10%      | fall  |        | Orders over 100 automatically get 20% discount           |
      | 200      | 20%      | none  | 160.00 |                                                          |
      | 200      | 20%      | apr   |        | 20% discount cannot be combined with promo               |
      | 200      | 20%      | fall  |        | 20% discount cannot be combined with promo               |
      +----------+----------+-------+--------+----------------------------------------------------------+
    _
  end

  let(:sets) { Fixtures[:pricing][:sets] }
  let(:rules) { Fixtures[:pricing][:rules] }

  it 'outputs with exclude inline full description' do
    result = CaseGen.generate(sets, rules, [:exclude_inline])
    expect(result).to eq expected_table
  end

  it 'outputs with exclude inline footnotes'
end
