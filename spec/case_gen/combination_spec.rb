# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CaseGen::Combination do
  it 'append' do
    combo = described_class.new([{a: 1}, {b: 2}])
    combo.append(:c, 3)
    expect(combo.hash_row).to eq({a: 1, b: 2, c: 3})
  end
end
