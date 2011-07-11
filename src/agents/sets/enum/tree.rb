#!/usr/bin/env ruby

module Enumerable

  class TreeDelegator
    include Enumerable
    
    attr_reader :root, :child_name, :child_map,
                :args, :output_type
    
    def initialize root, child_spec = nil, *args, &child_proc
      @root = root
      @args = args
      @output_type = :nodes
      
      case child_spec
      when Symbol
        @child_name = child_spec
      when String
        @child_name = child_spec.intern
      when nil
        @child_map = child_proc
      else
        unless child_spec.respond_to? :[]
          raise ArgumentError,
            "child_spec must be a method name or respond to []."
        end
        @child_map = child_spec
      end
      
      unless @child_name or @child_map
        raise ArgumentError,
          "no child-getter specified."
      end
    end
    
    def get_children cur
     (if @child_name
        cur.send @child_name, *@args
      else
        @child_map[cur, *@args]
      end).to_a
    end
    
  end
  
  class ByBreadthDelegator < TreeDelegator
  
    def each level = [@root], &block
    
      children = []
      for node in level
        yield node
        children |= get_children(node) || []
      end
      
      if children and not children.empty?
        each children, &block
      end

      self
    end
  
  end
  
  class ByDepthDelegator < TreeDelegator
    
    def with_ancestors
      @output_type = :with_ancestors
      self
    end
    
    def branches
      @output_type = :branches
      self
    end

    def each(*args, &block)
      case @output_type
      when :nodes
        each_node *args, &block
      when :with_ancestors
        each_with_ancestors *args, &block
      when :branches
        each_branch *args, &block
      end
    end
    
  protected
    def each_node cur = @root, &block
    
      result = catch (:prune) do
        yield cur
      
        children = get_children cur

        if children
          for child in children
            each_node child, &block
          end
        end
      
        false
      end

      if result and result > 0
        throw :prune, result - 1
      end

      self
    end
    
    def each_with_ancestors cur = @root, ancestors = [], &block

      result = catch (:prune) do
        yield cur, ancestors

        children = get_children cur

        if children
          for child in children
            each_with_ancestors child, ancestors + [cur], &block
          end
        end
        
        false
      end

      if result and result > 0
        throw :prune, result - 1
      end

      self
    end
    
    def each_branch branch = [@root], &block
      cur = branch[-1]
      
      children = get_children cur
      
      if children and not children.empty?
        for child in children
          each_branch branch + [child], &block
        end
      else
        yield branch
      end

      self
    end
        
  end
  
end

class Object
  def by_depth child_spec = nil, *args, &child_proc
    Enumerable::ByDepthDelegator.new self, child_spec, *args, &child_proc
  end
  def by_breadth child_spec = nil, *args, &child_proc
    Enumerable::ByBreadthDelegator.new self, child_spec, *args, &child_proc
  end
end


=begin

==class Object
===instance methods
---Object#by_depth child_spec = nil, *args, &child_proc
---Object#by_breadth child_spec = nil, *args, &child_proc

Allows use of (({Enumerable})) methods, such as (({each})), (({collect})),
(({select})), etc., to iterate over objects which have a caller-specified tree
structure (or, more generally, directed acyclic graph structure). The caller
defines this structure by providing a way of calculating the children of each
object, such as an accessor method for the array of children of a node in a
tree.

In order to yield a sequence of objects, the nonlinear structure of the tree is
linearized in either a depth-first or a breadth-first way, depending on the
method used, (({by_depth})) or (({by_breadth})). In a depth-first
linearization, the iteration visits a node's children before continuing with
the node's successive siblings. In a breadth-first linearization, the iteration
visits all siblings before visiting any of their children. In either case, the
parent is visited before its children, and the children are visited in an order
consistent with their order in the sequence of children provided by their
parent.

Speaking loosely, one can think of a depth-first iteration as working branch by
branch and a breadth-first iteration as working level by level, where a level
consists of nodes of equal depth.

====usage 

  require 'enum/tree'
  
  for node in root.by_depth :a_method, ...
  
  for node in root.by_depth a_proc, ...
  
  for node in root.by_depth { |node| ... return children }
  
  # by_breadth has the same form

====arguments

The means of accessing the children of each node is specified in the
argument list with a method name, a block, or an object that responds to
(({[]})), such as a proc or a hash. In any case, the value returned must be an
(({Enumerable})) object, typically an array.

If (({child_spec})) is a string or symbol, (({child_proc})) is ignored and
(({child_spec})) is treated as a method name. This method name is sent, along
with arguments (({args})), to each node to generate the children. The node is
considered childless when the method returns (({nil})) or (({false})) or an empty collection.

If (({child_spec})) is anything else, except (({nil})), (({child_proc})) is
ignored and (({child_spec})) is required to be an object that responds to
(({[]})), such as a proc or a hash. The (({[]})) method of (({child_spec})) is
called with each node as an argument, along with (({args})), to generate the
children. The node is considered childless when (({[]})) returns (({nil})) or
(({false})) or an empty collection.

If (({child_spec})) is not given, or is (({nil})), a block is required. In this
case, the block is converted to a proc and iteration proceeds as in the
preceding paragraph.

====return value

The return value is not an array, but an (({Enumerable})) object that refers
to the original objects. In this sense, (({Object#by_depth})) and
(({Object#by_breadth})) are ((*delegators*)). Typically, (({by_depth})) and
(({by_breadth})) are used with the (({for ... in ...})) construct, or
(equivalently) with (({each})), or with (({collect})), (({select})), and so on.
In these cases, the dependence on the original data structure does not matter.
To get the array of entries produced by (({by_depth})) or (({by_breadth})) as
an independent data structure, use (({Enumerable#entries})) or
(({Enumerable#to_a})).

====directed acyclic graphs

If a node occurs as the child of two different parent nodes, the structure is
not a tree. As long as no node is its own ancestor, these methods still produce
a useful interation (it is the caller's responsibility to avoid cycles). The
structure in this case is sometimes called a ((*directed acyclic graph*)). In a
depth-first iteration, a node with two parents will be reached twice. In a
breadth-first iteration, a node with two parents will be reaced once if the
parents are at the same depth in the graph, but twice otherwise.

====modifiers

The (({Object#by_depth})) method accepts two modifiers that affect the yielded
values, but not the order of iteration:

  for node, ancestors in tree.by_depth(...).with_ancestors
  
  for branch in tree.by_depth(...).branches

The (({with_ancestors})) modifier results in the same linearization, but
returns, along with each node, the node's array of ancestors, starting with the
root of the tree and ending with the immediate parent. In the non-tree case, the
ancestor list doesn't contain all ancestors, but just one path from the root to
the node. Each such path will occur once during the (({by_depth})) iteration.

With the (({branches})) modifier, the iteration yields all branches of the tree
(or directed acyclic graph). A ((*branch*)) is a path from the root to a leaf
node.

Note that a (({with_ancestors})) iteration yields at every node, but a
(({branches})) iteration yields only at leaf nodes.

====prune

Pruning the iteration means skipping a node and its descendants and continuing
with the nodes that would normally follow them in the iteration. This can be
done anywhere in dynamic scope during the iteration by simply throwing the
(({:prune})) symbol:

  throw :prune
  
If an additional integer argument is supplied:

  throw :prune, n
  
then the pruning occurs not at the current node, but at the node (({n})) levels
above the current node in the current ancestor list.

Note that (({prune})) cannot used with the (({each_branch})) modifier discussed
above; (({prune})) simply has no useful meaning in this context.

====examples

  require 'enum/tree'
  
  # Define a proc to compute the subclasses of a class
  # It would probably be better to make this a method of Class
  # and to implement it more efficiently, but for illustration...

  subclasses = proc { |cl|
    subs = []
    ObjectSpace.each_object(Class) { |sub|
      if sub.superclass == cl then subs << sub end
    }
    subs
  }
  
  print "Subclasses of Numeric:\n"
  for node in Numeric.by_depth subclasses
    print node, " "
  end
  
    # prints:
    # Subclasses of Numeric:
    # Numeric Float Integer Bignum Fixnum 

  puts "\n\nBranches:"
  for branch in Numeric.by_depth(subclasses).branches
    p branch
  end
  
    # prints:
    # Branches:
    # [Numeric, Float]
    # [Numeric, Integer, Bignum]
    # [Numeric, Integer, Fixnum]
  
  puts "\nNodes with ancestors:"
  for x, a in Numeric.by_depth(subclasses).with_ancestors
    print "\t"*a.size, "node is #{x}, ancestors is #{a.inspect}.\n"
  end
  
    # prints:
    # Nodes with ancestors:
    # node is Numeric, ancestors is [].
    #	 node is Float, ancestors is [Numeric].
    #	 node is Integer, ancestors is [Numeric].
    #		 node is Bignum, ancestors is [Numeric, Integer].
    #		 node is Fixnum, ancestors is [Numeric, Integer].
    
See the end of the source file for more examples.

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

  tree = [ [1,2,[3]], [4, [], 5] ]
  for x in tree.by_depth { |x| x.kind_of?(Array) ? x : [] }
    p x
  end
  puts
  
  class Node

    attr_reader :value, :children

    def initialize value, children = nil
      @value = value
      @children = children
      unless not children or children.respond_to? :each
        raise ArgumentError, "children must be nil or have an each method."
      end
    end

  end

  tree = Node.new(0,
    [Node.new(1,
      [Node.new(2,
        [Node.new(3)]),
       Node.new(4),
       Node.new(5)]),
     Node.new(6)])

  for node in tree.by_depth :children
    if node.value == 4
      throw :prune, 1
    end
    print node.value
  end
  puts
  
  for node in tree.by_breadth :children
    print node.value
  end
  puts
  
  # Define a proc to compute the subclasses of a Class
  # It would probably be better to make this a method of Class
  # and to implement it more efficiently, but for illustration...
  subclasses = proc { |cl|
    subs = []
    ObjectSpace.each_object(Class) { |sub|
      if sub.superclass == cl then subs << sub end
    }
    subs
  }
  
  print "\nSubclasses of Numeric:\n"
  for node in Numeric.by_depth subclasses
    print node, " "
  end
  print "\n\n"
  
  puts "Branches:"
  for branch in Numeric.by_depth(subclasses).branches
    p branch
  end
  puts
  
  puts "Nodes with ancestors:"
  for x, a in Numeric.by_depth(subclasses).with_ancestors
    print "\t"*a.size, "node is #{x}, ancestors is #{a.inspect}.\n"
  end
  puts
  
  # print the inheritance hierarchy of a given class
  if ARGV[0]
    root = Object.const_get(ARGV[0])
    for x, a in root.by_depth(subclasses).with_ancestors
      print "\t"*a.size, x, "\n"
    end
  end
  
end
