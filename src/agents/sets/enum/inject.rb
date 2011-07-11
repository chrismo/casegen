#!/usr/bin/env ruby

=begin
---Enumerable#inject
---Enumerable#sum [block]

Code adapted from Pickaxe book, p.102.
See source file for examples.

==version

Enumerable tools 1.6

=end

module Enumerable

  def inject n
    each { |i|
      n = yield n, i
    }
    n
  end
  alias :accumulate :inject
  
  def sum
    if block_given?
      inject(0) { |n, i| n + yield(i) }
    else
      inject(0) { |n, i| n + i }
    end
  end
  
  def product
    if block_given?
      inject(1) { |n, i| n * yield(i) }
    else
      inject(1) { |n, i| n * i }
    end
  end
  
end

if __FILE__ == $0

  x = (0..9).collect { |i| [i, i*i] }
  p x
  p x.sum { |v| v[1] }

end
