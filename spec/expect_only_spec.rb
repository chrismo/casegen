# frozen_string_literal: true

require 'spec_helper'
require_relative '../doc/expect_only'

RSpec.describe 'Exclude as table' do
  let(:expected_combo_table) do
    <<~_
      +----------+------+--------+
      | duration | unit | result |
      +----------+------+--------+
      | 12       | 60   | 12m    |
      | 12       | 3600 | 12h    |
      | 24       | 60   | 24m    |
      | 24       | 3600 | 1d     |
      | 36       | 60   | 36m    |
      | 36       | 3600 | 1d 12h |
      | 60       | 60   | 1h     |
      | 60       | 3600 | 2d 12h |
      +----------+------+--------+
    _
  end

  let(:fix) { Fixtures[:duration] }

  it 'output' do
    output = CaseGen.generate(fix[:sets], fix[:rules], :exclude_inline)
    expect(output.to_s).to eq expected_combo_table
  end
end
