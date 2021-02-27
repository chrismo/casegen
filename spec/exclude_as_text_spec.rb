# frozen_string_literal: true

require 'spec_helper'
require_relative '../doc/pricing'

RSpec.describe 'Exclude as text' do
  let(:expected_combo_table) do
    <<~_
      +----------+----------+-------+--------+
      | subtotal | discount | promo | total  |
      +----------+----------+-------+--------+
      | 25       | 0%       | none  | 25.00  |
      | 25       | 0%       | apr   | 17.50  |
      | 25       | 0%       | fall  | 16.25  |
      | 75       | 10%      | none  | 67.50  |
      | 75       | 10%      | apr   | 47.25  |
      | 75       | 10%      | fall  | 43.88  |
      | 200      | 20%      | none  | 160.00 |
      +----------+----------+-------+--------+
    _
  end

  let(:expected_exclude_as_text) do
    <<~_
      exclude
      -------
      subtotal < 100 && discount == '20%'
        Total must be above $100 to apply the 20% discount

      (subtotal < 50) && discount == '10%'
        Total must be above $50 to apply the 10% discount

      discount != '20%' && subtotal == 200
        Orders over 100 automatically get 20% discount

      discount != '10%' && subtotal == 75
        Orders between 50 and 100 automatically get 10% discount

      discount == '20%' && promo != 'none'
        20% discount cannot be combined with promo
    _
  end

  let(:generator) do
    fix = Fixtures[:pricing]
    CaseGen::Generator.new(fix[:sets], fix[:rules])
  end

  it 'output only combos table' do
    output = CaseGen::Exclude.new(generator)
    expect(output.to_s).to eq expected_combo_table
  end

  it 'outputs with exclude as text' do
    output = CaseGen::ExcludeAsText.new(generator)
    expect(output.to_s).to eq "#{expected_combo_table}\n#{expected_exclude_as_text}"
  end
end
