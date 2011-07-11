#!/usr/bin/env ruby

module Enumerable

  def nest(&compare)
    ary = to_a
    s = ary.size
    i = 0
    
    # wrap into Array::Iterator?
    items_left  = proc { i < s }
    get_cur     = proc { ary[i] }
    go_next     = proc { i += 1 }
    
    result = nil
    while items_left[]
      level_ary = Enumerable.nest items_left, get_cur, go_next, compare
      result = result ? level_ary.unshift(result) : level_ary
    end
    result || []
  end

  # Handles a single level, recursing when the depth increases and
  # backing out when the depth decreases.
  def Enumerable.nest items_left, get_cur, go_next, compare
    # should handle compare.arity == 2 like a <=> proc
    result = []; item = depth = nil
    while items_left[]
      item = get_cur[]
      depth = compare[item]
      base_depth ||= depth
        
      if depth < base_depth
        break
      elsif depth > base_depth
        result << nest(items_left, get_cur, go_next, compare)
      else
        result << item; go_next[]
      end
    end
    return result
  end
  
  def group(&test)
    nest { |x| test[x] ? 1 : 0 }
  end
end

=begin

=module Enumerable
==instance methods
---Enumerable#nest &compare

(({nest})) is an inverse for (({Array#flatten})). (Well, actually only a right
inverse since (({flatten})) is not injective.) You give it a proc that
calculates the depth of each item, and it returns a nesting of arrays in which
each item has the desired depth. It can be used to parse strings with
Python-like indentation syntax, but it isn't limited to strings.

The main improvement in this version is that the compare block can return
a lower value for an element after the first, with the expected effect. See the first example at the end of the source file.

===version

Enumerable tools 1.6

The current version of this software can be found at 
((<"http://redshift.sourceforge.net/enum
"|URL:http://redshift.sourceforge.net/enum>)).

===license
This software is distributed under the Ruby license.
See ((<"http://www.ruby-lang.org"|URL:http://www.ruby-lang.org>)).

===author
Joel VanderWerf,
((<vjoel@users.sourceforge.net|URL:mailto:vjoel@users.sourceforge.net>))

=end

if __FILE__ == $0

str = <<END
  a
   aa
   ab
    aba
    abb
     abba
      abbaa
     abbb
   ac
   ad
    ada
     adaa
    adb
  b
   ba
   bb
  c
   ca
X
 Y
  Z
END

lines = str.split "\n"
nested = lines.nest { |line| /\S/ =~ line }
p nested
flat = nested.flatten
p flat
p flat == lines

p [1, 2, "three", "four", 5, "six"].group { |x| x.is_a? String }

end
