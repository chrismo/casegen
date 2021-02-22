# frozen_string_literal: true

require 'spec_helper'
require_relative '../doc/bounding_box'

RSpec.describe 'Exclude as table' do
  let(:expected_combo_table) do
    <<~_
      +---------+---------+--------+---------+
      |  width  | height  | aspect | result  |
      +---------+---------+--------+---------+
      | inside  | inside  | wide   | 200x100 |
      | inside  | inside  | tall   | 100x200 |
      | inside  | outside | tall   | 100x400 |
      | outside | inside  | wide   | 400x100 |
      | outside | outside | wide   | 500x400 |
      | outside | outside | tall   | 400x500 |
      +---------+---------+--------+---------+
    _
  end

  let(:expected_exclude_as_table) do
    <<~_
      +---------+---------+--------+--------+--------------------------------------------+
      |  width  | height  | aspect | result |                  exclude                   |
      +---------+---------+--------+--------+--------------------------------------------+
      | inside  | outside | wide   |        | a narrower image cannot have a wide aspect |
      | outside | inside  | tall   |        | a shorter image cannot have a tall aspect  |
      +---------+---------+--------+--------+--------------------------------------------+
    _
  end

  let(:fix) { Fixtures[:box] }

  it 'output' do
    output = CaseGen.generate(fix[:sets], fix[:rules], [:exclude_as_table])
    expect(output.to_s).to eq "#{expected_combo_table}\n#{expected_exclude_as_table}"
  end
end
