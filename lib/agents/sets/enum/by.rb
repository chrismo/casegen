#!/usr/bin/env ruby

module Enumerable

  class LinkedListDelegator
    include Enumerable
    
    attr_reader :first, :next_name, :next_map, :args

    def initialize first, next_spec = nil, *args, &next_proc
      @first = first
      @args = args
      
      case next_spec
      when Symbol
        @next_name = next_spec
      when String
        @next_name = next_spec.intern
      when nil
        @next_map = next_proc
      else
        unless next_spec.respond_to? :[]
          raise ArgumentError,
            "next_spec must be a method name or respond to []."
        end
        @next_map = next_spec
      end
      
      unless @next_name or @next_map
        raise ArgumentError,
          "no next-getter specified."
      end
    end

    def each
      cur = @first
      if @next_name
        next_name = @next_name
        message = next_name, *@args
        while cur
          yield cur
          cur = cur.send *message
        end
      elsif @next_map
        next_map = @next_map
        args = @args
        while cur
          yield cur
          cur = next_map[cur, *args]
        end
      end

      self
    end
    
  end
  
end

class Object
  def by next_spec = nil, *args, &next_proc
    Enumerable::LinkedListDelegator.new self, next_spec, *args, &next_proc
  end
end


=begin

==class Object
===instance method
---Object#by next_spec = nil, *args, &next_proc

Allows use of (({Enumerable})) methods, such as (({each})), (({collect})),
(({select})), etc., to iterate over arbitrary objects. The caller supplies a
way of calculating the successor of each object, such as an accessor method for
the next element of a linked list.

Object#by returns an (({Enumerable})) object whose (({each})) method
iterates over the sequence beginning with (({self})) and continuing as
specified by the arguments. Only the current element of the sequence is
kept in memory. No attempt is made to avoid cycles.

If (({next_spec})) is a string or symbol, (({next_proc})) is ignored and
(({next_spec})) is treated as a method name. This method name is sent, along
with arguments (({args})), to each element of the sequence to generate the next
element. The sequence terminates at the first element for which the method
returns (({nil})) or (({false})).

If (({next_spec})) is anything else, except (({nil})), (({next_proc})) is
ignored and (({next_spec})) is required to be an object that responds to
(({[]})), such as a proc or a hash. The (({[]})) method of (({next_spec}))
is called with each element of the sequence in turn as an argument, along
with (({args})), to generate the next element. The sequence terminates at
the first element for which (({[]})) returns (({nil})) or (({false})).

If (({next_spec})) is not given, or is (({nil})), a block is required. In this
case, the block is converted to a proc and iteration proceeds as in the
preceding paragraph.

The return value is not an array, but an (({Enumerable})) object that refers
to the original objects. In this sense, (({Object#by})) is a ((*delegator*)).
Typically, (({by})) is used with the (({for .. in ..})) construct, or
(equivalently) with (({each})), or with (({collect})), (({select})), and so on.
In these cases, the dependence on the original sequence does not matter. To get
the array of entries produced by (({by})) as an independent data structure, use
(({Enumerable#entries})) or (({Enumerable#to_a})).

===examples

  require 'enum/by'

  class A; end
  class B < A; end
  class C < B; end

  for cl in C.by :superclass
    print cl, " "
  end

  # prints: C B A Object

  steps = proc { |x, incr, limit| y = x + incr; y <= limit ? y : nil }
  p 0.by(steps, 10, 50).to_a

  # prints: [0, 10, 20, 30, 40, 50]
  
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

==acknowledgement
Thanks to David Alan Black for his helpful comments on the Ruby mailing
list
((<"http://blade.nagaokaut.ac.jp/ruby/ruby-talk
"|URL:http://blade.nagaokaut.ac.jp/ruby/ruby-talk>)).

=end


if __FILE__ == $0

  class Foo
    attr_reader :value, :next_foo

    def initialize value, next_foo = nil
      @value = value
      @next_foo = next_foo
    end
  end

  list = Foo.new(0, Foo.new(1, Foo.new(2, Foo.new(3))))

  puts "Iterating over a linked list by method next_foo:"
  for foo in list.by :next_foo
    print "#{foo.value} "
  end
  print "\n\n"

  puts "By proc { |foo| foo.next_foo.next_foo }:"
  for foo in list.by { |foo| foo.next_foo.next_foo }
    print "#{foo.value} "
  end
  print "\n\n"

  puts "Down a tree, taking a random branch at each node:"
  puts "First, with a proc:"
  tree = [[0, [1, 2]], 3, [4, 5, [6, 7, 8]], 9]
  at_random = proc { |x| x.kind_of?(Array) && x.at(rand(x.size)) }
  for node in tree.by at_random
    p node
  end
  puts "Second, with methods:"
  class Object
    def at_random
      nil
    end
  end
  class Array
    def at_random
      at(rand(size))
    end
  end
  for node in tree.by :at_random
    p node
  end
  puts

  puts "With numbers (but watch out for cycles!):"
  p 0.by { |x| x<10 ? x+1 : nil }.to_a
  puts

  puts "With numbers using a proc and an argument:"
  steps = proc { |x, incr, limit| y = x + incr; y <= limit ? y : nil }
  p 0.by(steps, 10, 50).to_a
  puts

  puts "Up the superclass relation:"
  class A; end
  class B < A; end
  class C < B; end
  for cl in C.by :superclass
   print cl, " "
  end
  puts "\n\n"

  puts "Popping down a stack:"
  p [0,1,2,3,4].by { |y| y.pop; y != [] && y.dup }.entries
  puts

  puts "#by behaves correctly with self==nil"
  p nil.by(:something).entries
  puts

  puts "By hash, or other class responding to []:"
  h = { :a => :b, :b => :c, :c => :d }
  p :a.by {|x| h[x]}.entries
  puts "The same effect, but simpler:"
  p :a.by(h).entries
  puts

  puts "Around and around we go..."
  n = 0;
  for x in 0.by([1,2,3,4,0])
    n += 1
    print x, " "
    break if n > 12
  end
  puts "..."

end
