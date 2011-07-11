#!/usr/bin/env ruby

module Enumerable

  class Pipe
    include Enumerable
    
    attr_reader :enum, :filter_name, :filter_map, :args

    def initialize enum, filter_spec = nil, *args, &filter_proc
      @enum = enum
      @args = args
      
      case filter_spec
      when Symbol
        @filter_name = filter_spec
      when String
        @filter_name = filter_spec.intern
      when nil
        @filter_map = filter_proc
      else
        unless filter_spec.respond_to? :[]
          raise ArgumentError,
            "filter_spec must be a method name or respond to []."
        end
        @filter_map = filter_spec
      end
      
      unless @filter_name or @filter_map
        raise ArgumentError,
          "no filter specified."
      end
    end

    def each
      if @filter_name
        filter_name = @filter_name
        message = filter_name, *@args
        @enum.each { |entry|
          yield entry.send *message
        }
      elsif @filter_map
        filter_map = @filter_map
        args = *@args
        @enum.each { |entry|
          yield filter_map[entry, *args]
        }
      end
    end
    
    self
  end
  
  def pipe filter_spec = nil, *args, &filter_proc
    Pipe.new self, filter_spec, *args, &filter_proc
  end

end


=begin

==class Enumerable
===instance method
---Enumerable#pipe filter_spec = nil, *args, &filter_proc

Can be used to "pipe" an (({Enumerable})) sequence through a filter.

(({Enumerable#pipe})) returns an (({Enumerable})) object whose (({each}))
method iterates over (({self})) and applies a filter to each enumerated
object, as specified by the arguments. Only the current element of the
sequence is kept in memory.

If (({filter_spec})) is a string or symbol, (({filter_proc})) is ignored
and (({filter_spec})) is treated as a method name. This method name is
sent, along with arguments (({args})), to each element of the sequence
being  enumerated.

If (({filter_spec})) is anything else, except (({nil})), (({filter_proc}))
is ignored and (({filter_spec})) is required to be an object that responds
to (({[]})), such as a proc or a hash. The (({[]})) method of
(({filter_spec})) is called with each element of the sequence in turn as
an argument, along with (({args})).

If (({next_spec})) is not given, or is (({nil})), a block is required. In
this case, iteration proceeds as in the preceding paragraph.

Using (({#pipe})) has potential performance advantages. The iteration

  e.collect { |x| x.m }.each { |y| ... }

can be rewritten as

  e.pipe(:m).each { |y| ... }

which doesn't generate an intermediate array, and uses a send instead of a
proc call. Of course, it could also be written as

  e.each { |x| y = x.m ... }

but that may be undesirable for readability or because the block is to be
taken from a proc contained in a variable:

  pr = proc { ... }
  e.pipe(:m).each &pr

Also, chains of (({collect})) and (({select})), such as

  (1..100).collect { |x| x**2 }.select { |y| y > 1000 && y < 2000 }

can't be easily rewritten as a single (({select})).

===examples

  require 'enum/pipe'

  [0,1,2,3,4].pipe { |x| x + 1 }.each { |x|
    print x, " "
  }
  
  # prints: 1 2 3 4 5
  
  stooges = ['lARRY', 'cURLY', 'mOE']
  p stooges.pipe(:swapcase).reject { |x| x =~ /url/ }
  p stooges.pipe(:tr, 'RlcOEL', 'gBboog').pipe(:capitalize).entries
  
  # prints:  ["Larry", "Moe"]
  #          ["Baggy", "Buggy", "Moo"]

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

  [0,1,2,3,4].pipe { |x| x + 1 }.each { |x|
    print x, " "
  }
  puts

  stooges = ['lARRY', 'cURLY', 'mOE']
  p stooges.pipe(:swapcase).reject { |x| x =~ /url/ }
  p stooges.pipe(:tr, 'RlcOEL', 'gBboog').pipe(:capitalize).entries

end
