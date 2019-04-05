#!/usr/bin/env ruby

require 'enum/inject'

module EnumerableOperator

  class Product
    include Enumerable

    attr_reader :factors, :dim

    def initialize(*factors)
      @factors = factors
      @dim = @factors.length
    end

    def each tuple = [nil]*@dim, i = 0, &block
      if i == @dim - 1 then
        @factors[i].each { |x| tuple[i] = x; yield tuple.dup }
      elsif i > 0
        @factors[i].each { |x| tuple[i] = x; each tuple, i + 1, &block }
      else
        @factors[i].each { |x| tuple[i] = x; each tuple, i + 1, &block }
        self
      end
    end

    def size
      @factors.product { |enum| enum.size }
    end

  end

  class Sum
    include Enumerable

    attr_reader :summands

    def initialize(*summands)
      @summands = summands
    end

    def each(&block)
      @summands.each { |enum| enum.each(&block) }
      self
    end
    
    def size
      @summands.sum { |enum| enum.size }
    end

  end

  class Diagonal
    include Enumerable
  
    attr_reader :factors, :dim

    def initialize(*factors)
      @factors = factors
      @dim = @factors.length
    end
    
    def each
      factors = @factors.map { |factor|
        if factor.kind_of? Array then factor else factor.entries end
      }
      minlength = factors.min { |f, g| f.length <=> g.length }.length
      for i in 0..(minlength-1)
        yield factors.map { |factor| factor[i] }
      end
      self
    end
  end


  def product(*factors, &block)
    if block
      Product.new(*factors).each(&block)
    else
      Product.new(*factors)
    end
  end
  alias :tuples :product

  def sum(*summands, &block)
    if block
      Sum.new(*summands).each(&block)
    else
      Sum.new(*summands)
    end
  end
  alias :concatenation :sum
  alias :cat :sum

  def diagonal(*factors, &block)
    if block
      Diagonal.new(*factors).each(&block)
    else
      Diagonal.new(*factors)
    end
  end

  module_function :product, :sum, :diagonal
end

=begin

==module EnumerableOperator
===instance methods and module methods
---EnumerableOperator#product *factors, &block
---EnumerableOperator#sum *summands, &block

The (({product})) operator iterates over the Cartesian product of the factors,
each of which must be (({Enumerable})).

The (({sum})) operator iterates over the concatenation of the summands, each of
which must be (({Enumerable})).

Both operators have aliases: (({tuples})) for (({product}));
(({concatenation})) and (({cat})) for (({sum})).

Called with a block, the operators yield one element of the sequence at a time
to the block.

With or without a block, the operators return an (({Enumerable})) which
delegates to the original (({Enumerables})), but does not explicitly construct
the entire collection. Calling another (({Enumerable})) method, such as
(({select})) or (({collect})), on this return value is an efficient way of
chaining these operators with other methods. Simply call (({entries})) to get
the whole collection. Also, because the operators return an (({Enumerable})),
they can be used with the (({for})) syntax; see the examples.

---EnumerableOperator#diagonal *factors, &block

The (({diagonal})) operator iterates over the diagonal of the Cartesian product
of the factors, each of which must be (({Enumerable})). In other words, the
n-th entry of the diagonal is an array of the n-th entries of each factor. The
resulting sequence terminates when any one factor terminates. Hence the
sequence has the same length as the shortest factor.

Called with a block, (({diagonal})) yields one element of the sequence at a
time to the block.

With or without a block, (({diagonal})) returns an (({Enumerable})) object
which is ((*independent*)) of the original (({Enumerables})). As with
(({product})) and (({sum})), this allows chaining with other iterators and
using the (({for})) syntax. Unlike (({product})) and (({sum})), however, the
entire collection is generated and stored in the object returned by
(({diagonal})).

Internally, (({diagonal})) does not enumerate the sequences in parallel, but in
the order in which they are given. If the sequences have side-effects of
enumeration, this may result in different behavior than if the sequences were
truly enumerated in parallel (e.g., see matz's approach using threads in the
Ruby FAQ:  ((<"http://www.rubycentral.com/faq/rubyfaq-5.html#ss5.5
"|URL:http://www.rubycentral.com/faq/rubyfaq-5.html#ss5.5>))).

===usage

  include EnumerableOperator
  diagonal enum0, enum1, ...
or
  EnumerableOperator.diagonal enum0, enum1, ...
and similarly for product and sum.

===examples

  require 'enum/op'
  include EnumerableOperator
  
  # using the 'for ... in ... end' construct:
  for i, j in product 1..4, "bar".."baz"
    printf "%6s", i.to_s + j; puts if j == "baz"
  end
  puts
  
  # prints:
  #  1bar  1bas  1bat  1bau  1bav  1baw  1bax  1bay  1baz
  #  2bar  2bas  2bat  2bau  2bav  2baw  2bax  2bay  2baz
  #  3bar  3bas  3bat  3bau  3bav  3baw  3bax  3bay  3baz
  
  # directly passing a block:
  sum 1..5, 'a'..'c', 90..92 do |i|
    printf "%4s", i.to_s
  end
  puts "\n\n"
  
  # prints:
  #   1   2   3   4   5   a   b   c  90  91  92

  for i, j, k in diagonal 1..4, 'a'..'d', ?a..?d
    printf "%4d. %s is 0x%x\n", i, j, k
  end
  puts

  # prints:
  #   1. a is 0x61
  #   2. b is 0x62
  #   3. c is 0x63
  #   4. d is 0x64

  # chaining with other iterators:
  names = %w{ Ludwig Rudolf Bertrand Willard }
  more_names = %w{ Jean-Paul Albert Martin Soren }
  puts sum(names, more_names).sort.join ', '
  puts

  # prints:
  #   Albert, Bertrand, Jean-Paul, Ludwig, Martin, Rudolf, Soren, Willard
  
  # note that chaining avoids constructing the intermediate collection:
  big_product = product 1..10, 1..10, 1..10
  big_product.select { |x, y, z|
    x <= y and x**2 + y**2 == z**2
  }.each { |x, y, z|
    printf "#{x}**2 + #{y}**2 == #{z}**2\n"
  }
  
  # prints:
  #   3**2 + 4**2 == 5**2
  #   6**2 + 8**2 == 10**2
  
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

  include EnumerableOperator

  # using the 'for ... in ... end' construct:
  for i, j in product 1..4, "bar".."baz"
    printf "%6s", i.to_s + j; puts if j == "baz"
  end
  puts
  
  # directly passing a block:
  sum 1..5, 'a'..'c', 90..92 do |i|
    printf "%4s", i.to_s
  end
  puts "\n\n"
  
  for i, j, k in diagonal 1..4, 'a'..'d', ?a..?d
    printf "%4d. %s is 0x%x\n", i, j, k
  end
  puts
  
  # chaining with other iterators:
  names = %w{ Ludwig Rudolf Bertrand Willard }
  more_names = %w{ Jean-Paul Albert Martin Soren }
  puts sum(names, more_names).sort.join(', ')
  puts
  
  # note that chaining avoids constructing the intermediate collection:
  big_product = product 1..10, 1..10, 1..10
  big_product.select { |x, y, z|
    x <= y and x**2 + y**2 == z**2
  }.each { |x, y, z|
    printf "#{x}**2 + #{y}**2 == #{z}**2\n"
  }
  puts
  
  # size
  puts "sum(1..10,11..20).size     = #{sum(1..10,11..20).size}"
  puts "product(1..10,11..20).size = #{product(1..10,11..20).size}"
  puts "product([1,2,3],[]).size   = #{product([1,2,3],[]).size}"
end
