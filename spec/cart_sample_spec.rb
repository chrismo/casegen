# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cart Sample' do
  let(:expected) do
    <<~_
      +-------------+--------+----------+-----------------+-----------------+
      |   payment   | amount | shipping | ship_to_country | bill_to_country |
      +-------------+--------+----------+-----------------+-----------------+
      | Credit      | 100    | Ground   | US              | US              |
      | Credit      | 100    | Air      | US              | US              |
      | Credit      | 100    | Air      | Outside US      | US              |
      | Credit      | 100    | Air      | Outside US      | Outside US      |
      | Credit      | 1000   | Ground   | US              | US              |
      | Credit      | 1000   | Air      | US              | US              |
      | Credit      | 1000   | Air      | Outside US      | US              |
      | Credit      | 1000   | Air      | Outside US      | Outside US      |
      | Credit      | 10000  | Ground   | US              | US              |
      | Credit      | 10000  | Air      | US              | US              |
      | Credit      | 10000  | Air      | Outside US      | US              |
      | Credit      | 10000  | Air      | Outside US      | Outside US      |
      | Check       | 100    | Ground   | US              | US              |
      | Check       | 100    | Air      | US              | US              |
      | Check       | 100    | Air      | Outside US      | US              |
      | Check       | 1000   | Ground   | US              | US              |
      | Check       | 1000   | Air      | US              | US              |
      | Check       | 1000   | Air      | Outside US      | US              |
      | Check       | 10000  | Ground   | US              | US              |
      | Check       | 10000  | Air      | US              | US              |
      | Check       | 10000  | Air      | Outside US      | US              |
      | Online Bank | 100    | Ground   | US              | US              |
      | Online Bank | 100    | Air      | US              | US              |
      | Online Bank | 100    | Air      | Outside US      | US              |
      | Online Bank | 100    | Air      | Outside US      | Outside US      |
      +-------------+--------+----------+-----------------+-----------------+
    _
  end

  it 'works' do
    require_relative '../doc/cart.sample'

    expect(CaseGen::Generator.new(Fixtures.sets, Fixtures.rules).combos_table.to_s).to eq expected
  end
end
