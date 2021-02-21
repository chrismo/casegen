# frozen_string_literal: true

require_relative '../lib/casegen'

sets = {
  payment: ['Credit', 'Check', 'Online Bank'],
  amount: [100, 1_000, 10_000],
  shipping: ['Ground', 'Air'],
  ship_to_country: ['US', 'Outside US'],
  bill_to_country: ['US', 'Outside US']
}

rules = {
  exclude: [
    {
      criteria: %(shipping == "Ground" && ship_to_country == "Outside US" ),
      description: 'Our ground shipper will only ship things within the US',
    },
    {
      criteria: -> { payment == 'Check' && bill_to_country == 'Outside US' },
      description: 'Our bank will not accept checks written from banks outside the US.',
    },
    {
      criteria: -> { payment == 'Online Bank' && amount >= 1_000 },
      description: <<~_,
        While the online bank will process amounts > $1,000, we've experienced
        occasional problems with their services and have had to write off some
        transactions, so we no longer allow this payment option for amounts
        greater than $1,000.
      _
    },
    {
      criteria: -> { ship_to_country == 'US' && bill_to_country == 'Outside US' },
      description: "If we're shipping to the US, billing party cannot be outside US"
    },
  ]
}

if __FILE__ == $PROGRAM_NAME
  puts CaseGen.generate(sets, rules, [:exclude_as_text]).to_s
else
  Fixtures.add(:cart, sets, rules)
end
