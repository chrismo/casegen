#!/usr/bin/env ruby

module Enumerable
  
  def each_cluster n = 2
    tuple = [nil] * n
    
    count = n-1
    each { |x|
      tuple.shift
      tuple.push x
      if count == 0
        yield tuple
      else
        count -= 1
      end
    }
  end

  def each_with_neighbors n = 1, empty = nil
    nbrs = [empty] * (2 * n + 1)
    offset = n
    
    each { |x|
      nbrs.shift
      nbrs.push x
      if offset == 0  # offset is now the offset of the first element, x0,
        yield nbrs    #   of the sequence from the center of nbrs, or 0,
      else            #   if x0 has already passed the center.
        offset -= 1
      end
    }
    
    n.times {
      nbrs.shift
      nbrs.push empty
      if offset == 0
        yield nbrs
      else
        offset -= 1
      end
    }
        
    self
  end

end


=begin

==module Enumerable
===instance methods
---Enumerable#each_cluster n = 2
---Enumerable#each_with_neighbors n = 1, empty = nil

Both methods iterate over a collection of arrays whose elements are drawn
in sequence from the original collection.

In the case of (({each_cluster})), the iteration yields all contiguous
subsequences of length ((|n|)). If the argument to (({each_cluster})) is 0
or larger than the size of the collection, the iteration yields no values.

In the case of (({each_with_neighbors})), the iteration yields one
sequence for each element ((|x|)) of the collection. The yielded sequence
includes the ((|n|)) elements before and after ((|x|)). Elements out of
bounds are filled with ((|empty|)). The first argument can be any
nonnegative integer.

===examples

  require 'enum/cluster'
  
  (0..5).each_with_neighbors { |x| p x }

  # prints: 
  # [nil, 0, 1]
  # [0, 1, 2]
  # [1, 2, 3]
  # [2, 3, 4]
  # [3, 4, 5]
  # [4, 5, nil]

  [1,2,3,4].each_with_neighbors(8, 0) { |x| p x }
  
  # prints: 
  # [0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0]
  # [0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0]
  # [0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0]
  # [0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0]

  ('a'..'g').each_cluster(5) { |x| p x.join '' }

  # prints: 
  # "abcde"
  # "bcdef"
  # "cdefg"

See the end of the source file for more examples.

==version

Enumerable tools 1.6

The current version of this software can be found at 
((<"http://redshift.sourceforge.net/enum
"|URL:http://redshift.sourceforge.net/enum>)).

==license
This software is distributed under the Ruby license.
See ((<"http://www.ruby-lang.org"|URL:http://www.ruby-lang.org>)).

==author
Joel VanderWerf,
((<vjoel@users.sourceforge.net|URL:mailto:vjoel@users.sourceforge.net>))

=end


if __FILE__ == $0

  (0..5).each_with_neighbors { |x| p x }
  
  puts
  
  [1,2,3,4].each_with_neighbors(8, 0) { |x| p x }
  
  puts
  
  ('a'..'g').each_cluster(5) { |x| p x.join '' }
  
  puts
  
  begin
    require 'enum/by'
    
    # each_with_neighbors is useful for successive comparisons:
    2.by {|x| x<10000 && x**2}.each_with_neighbors(1, 1) {
      |prev_x, x, next_x|
      printf "%d - %d = %d\n", x, prev_x, x - prev_x
    }
    puts

    # Construct a doubly linked list:
    Node = Struct.new "Node", :value, :prev_node, :next_node
    
    list = (1..10).collect { |i| Node.new i }
    
    list.each_with_neighbors { |prev_node, node, next_node|
      node.prev_node = prev_node
      node.next_node = next_node
    }
    
    list[0].by(:next_node).each { |node| print node.value, " " }
    puts
    
    # We constructed the list and interated over it without ever
    # explicitly mentioning nil.
    
  rescue LoadError
    puts "File enum/by.rb not available. You're missing the best part!"
  end

end
