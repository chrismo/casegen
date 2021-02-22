# frozen_string_literal: true

require_relative '../lib/casegen'

# Presuming a 300x300 bounding box, we need images to test edge cases.

bounding_box_relation = %w[inside outside]

sets = {
  width: bounding_box_relation,
  height: bounding_box_relation,
  aspect: %w[wide tall],
  result: [:expect]
}

rules = {
  exclude: [
    {width: 'inside', height: 'outside', aspect: 'wide',
     note: 'a narrower image cannot have a wide aspect'},
    {width: 'outside', height: 'inside', aspect: 'tall',
     note: 'a shorter image cannot have a tall aspect'},
  ],
  expect: [
    {width: 'inside', height: 'inside', aspect: 'wide', result: '200x100'},
    {width: 'inside', height: 'inside', aspect: 'tall', result: '100x200'},
    {width: 'inside', height: 'outside', aspect: 'tall', result: '100x400'},
    {width: 'outside', height: 'inside', aspect: 'wide', result: '400x100'},
    {width: 'outside', height: 'outside', aspect: 'wide', result: '500x400'},
    {width: 'outside', height: 'outside', aspect: 'tall', result: '400x500'},
  ]
}

if __FILE__ == $PROGRAM_NAME
  puts CaseGen.generate(sets, rules, [:exclude_as_table]).to_s
else
  Fixtures.add(:box, sets, rules)
end
