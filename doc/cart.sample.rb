# frozen_string_literal: true

require_relative '../lib/case_gen'

sets = {
  payment: ['Credit', 'Check', 'Online Bank'],
  amount: [100, 1_000, 10_000],
  shipping: ['Ground', 'Air'],
  ship_to_country: ['US', 'Outside US'],
  bill_to_country: ['US', 'Outside US']
}

# TODO: lambda rules cannot be output**. Outputting the exclusion rules is nice
# since these are still things that should be tested. In some scenarios, just
# outputting the excluded combinations could be good, but in more complex
# setups, the exclusion rules are used to remove large swaths of cases that are
# too costly to verify.
#
# TODO: ... but anyway, should output the string versions.
#
# ** Yes I'm sure. Dug into pry and its magic - it can show-source on a lambda
# entered into pry on the fly, but it uses pry magic to capture things like
# that. Doing it from a Hash I couldn't get to work.
#
# Now, if we switched this here to subclassing something, then presumably we
# could get an output of the lambda or method ... though I dunno if it'd be as
# tidy. And ... what's the big diff between a string and a lambda? Well, syntax
# highlighting, but you don't get much more than that since there's no proper
# context inside the lambda to do things like proper discovery of methods, etc.
# at least in RubyMine.

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
  puts CaseGen::Executor.new(sets, rules).to_table
else
  Fixtures.sets = sets
  Fixtures.rules = rules
end
