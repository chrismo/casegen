# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pricing Sample' do
  let(:expected) do
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

  it 'works' do
    require_relative '../doc/pricing.sample'

    expect(CaseGen::Executor.new(Fixtures.sets, Fixtures.rules).to_table.to_s).to eq expected
  end
end
