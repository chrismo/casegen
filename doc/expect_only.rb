# frozen_string_literal: true

require_relative '../lib/casegen'

sets = {
  duration: [12, 24, 36, 60],
  unit: [60, 3600],
  result: [:expect]
}

rules = {
  expect: [
    {duration: 12, unit: 60, result: '12m'},
    {duration: 12, unit: 3600, result: '12h'},
    {duration: 24, unit: 60, result: '24m'},
    {duration: 24, unit: 3600, result: '1d'},
    {duration: 36, unit: 60, result: '36m'},
    {duration: 36, unit: 3600, result: '1d 12h'},
    {duration: 60, unit: 60, result: '1h'},
    {duration: 60, unit: 3600, result: '2d 12h'},
  ]
}

if __FILE__ == $PROGRAM_NAME
  puts CaseGen.generate(sets, rules, :exclude_inline).to_s
else
  Fixtures.add(:duration, sets, rules)
end
