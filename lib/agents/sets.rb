require "#{File.dirname(__FILE__)}/../casegen"
$LOAD_PATH << "#{File.expand_path(File.join(File.dirname(__FILE__), 'sets'))}"
require 'enum/op'
require 'tablesmith'

class String
  def to_u
    self.gsub(/ /, '_')
  end
end

module CLabs::CaseGen
  class Set
    attr_reader :name, :data

    def initialize(name, data_array)
      @name = name
      @data = data_array
      strip_data
    end

    def strip_data
      @data.collect! { |datum| datum.strip }
    end

    def values
      @data
    end
  end

  class ExpectSet < Set

  end

  class Sets < Agent
    attr_accessor :sets, :combinations, :set_titles

    def Sets.agent_id
      "casegen:sets"
    end

    def initialize(data, reference_agents = nil)
      @data = data
      @sets = []
      parse_sets
    end

    def parse_sets
      set_names = @data.scan(/^\s*(\w.*):/)
      set_data = @data.scan(/:(.*)/)
      sets = set_names.flatten.zip(set_data.flatten)
      sets.each do |set_array|
        name, data_array = [set_array[0], set_array[1].split(/, /)]
        new_set =
          if /\Aexpect/i.match?(name)
            ExpectSet.new(name, data_array)
          else
            Set.new(name, data_array)
          end
        @sets << new_set
      end
      generate_combinations
    end

    def generate_combinations
      @combinations =
        begin
          @set_titles = []
          @sets.each { |set| @set_titles << set.name }
          combo_sets, expect_sets = @sets.partition { |set| set.class == CLabs::CaseGen::Set }
          arrays = combo_sets.map { |set| set.data.map { |d| {set.name => d} } }
          combos = all(*arrays)
          combos.each { |combo| expect_sets.each { |expect_set| combo << {expect_set.name => ''} } }
        end
    end

    def titles
      @set_titles
    end

    def all(*args)
      EnumerableOperator::Product.new(*args).to_a
    end

    def set_names
      @sets.map(&:name)
    end

    def set_by_name(setname)
      @sets.detect { |set| set.name =~ /#{Regexp.escape(setname)}/ }
    end
  end

  class Criteria
    attr_reader :set_names, :set_values, :equalities

    def initialize(data)
      @data = data
      @equalities = {}
      parse
    end

    def parse
      @data.split(/AND/).each do |bit|
        set_name, set_value = bit.split(/==|=/)
        set_name.strip!; set_value.strip!
        if @equalities.keys.include?(set_name)
          raise ParserException.new("Rule cannot have the same set <#{set_name}> equal to different values <#{@equalities[set_name]}, #{set_value}>")
        end
        @equalities[set_name] = set_value
      end
      @set_names = @equalities.keys
      @set_values = @equalities.values
    end

    # hash keys should be valid set names and hash values should be valid
    # set values in the named set
    def match(hash)
      # must match all equalities
      @equalities.each_pair do |eq_name, eq_value|
        actual_value = hash[eq_name]
        return false if actual_value.nil?
        return false if actual_value != eq_value
      end
      return true
    end

    def to_s
      @data
    end
  end

  class Rule
    attr_reader :criteria, :description, :data

    def initialize(rule_data)
      @data = rule_data
      parse_rule
    end

    def parse_rule
      data = @data.sub(self.class.regexp, '')
      criteria_data, *@description = data.split(/\n/)
      criteria_data.strip!
      @criteria = Criteria.new(criteria_data)
      @description = (@description.join("\n") + "\n").outdent.strip
    end
  end

  class ExcludeRule < Rule
    def ExcludeRule.regexp
      /^exclude/i
    end

    def ExcludeRule.create(rule_data)
      return ExcludeRule.new(rule_data) if rule_data =~ regexp
      return nil
    end

    def process_combo(combo)
      return criteria.match(combo)
    end
  end

  class WhenExpectRule < Rule
    def self.regexp
      /\Awhen/i
    end

    def self.create(rule_data)
      return WhenExpectRule.new(rule_data) if rule_data =~ regexp
      return nil
    end

    def parse_rule
      super

      @value = description.scan(/\A\s*expect\s*=\s*(.*)/).join
    end

    def process_combo(combo)
      combo["expect"] = @value if criteria.match(combo)

      return false
    end
  end

  class Rules < Agent
    def Rules.agent_id
      "casegen:rules"
    end

    def initialize(data, reference_agents = [])
      @data = data
      @agents = reference_agents
      @rules = []
      @rule_classes = []
      ObjectSpace.each_object(Class) do |obj|
        @rule_classes << obj if obj.ancestors.include?(Rule) && obj != Rule
      end
      parse_data
    end

    def parse_data
      raw_rules = @data.split(/(?=^\S)/)

      raw_rules.each do |rule|
        @rule_classes.each do |rule_class|
          @rules << rule_class.create(rule.strip)
        end
      end
      @rules.compact!
      @rules.flatten!
      validate_rules
    end

    def validate_rules
      @agents.each do |agent|
        if agent.class == Sets
          @rules.each do |rule|
            rule.criteria.equalities.each_pair do |set_name, set_value|
              set = agent.set_by_name(set_name)
              if set.nil?
                raise ParserException.new(
                  "Invalid set name <#{set_name}> " +
                    "in rule <#{rule.criteria}>. Valid set names are <#{agent.set_names.join(', ')}>.")
              end
              if !set.values.include?(set_value)
                raise ParserException.new(
                  "Invalid set value <#{set_value}> " +
                    "in rule <#{rule.criteria}>. Valid set values for <#{set.name}> " +
                    "are <#{set.values.join(', ')}>.")
              end
            end
          end
        end
      end
    end

    def length
      @rules.length
    end

    def [](index)
      return @rules[index]
    end

    def each(&block)
      @rules.each(&block)
    end

    def combinations
      return @combinations if defined?(@combinations) && !@combinations.nil?
      if @agents[0].class == Sets
        agent = @agents[0]
        @combinations = []
        agent.combinations.each do |combo|
          delete = false

          # TODO: don't make Rules make the hash like this, have Sets do it this way.
          combo_hash = combo.reduce({}) {|h, d| h.merge(d) }
          @rules.each { |rule| delete ||= rule.process_combo(combo_hash) }
          @combinations << combo_hash.values unless delete
        end
        return @combinations
      end
      return []
    end

    def titles
      @agents[0].titles
    end

    def to_s
      puts @agents[0].combinations.inspect if !@agents[0].nil?
      puts
      puts @rules.inspect
    end
  end

  class ConsoleOutput < Agent
    def ConsoleOutput.agent_id
      "casegen:console"
    end

    def initialize(data, reference_agents, io = STDOUT)
      @data = data
      @agents = reference_agents
      table = [@agents[0].titles] + @agents[0].combinations
      io.puts table.to_table.pretty_inspect
      io.puts
      @agents[0].each do |rule|
        io.puts rule.data
        io.puts
      end if @agents[0].is_a?(Rules)
    end
  end

  class RubyArrayOutput < Agent
    def self.agent_id
      "casegen:ruby_array"
    end

    def initialize(data, reference_agents, io = STDOUT)
      @io = io
      @struct_name = "Case"
      @struct_name = data if !data.empty?
      @agents = reference_agents
      @agents.each { |agent| execute(agent) }
    end

    def execute(agent)
      struct_header = "#{@struct_name} = Struct.new("
      struct = ''
      agent.titles.each do |title|
        struct << ', ' if !struct.empty?
        struct << ":#{title.to_u.downcase}"
      end
      struct << ')'

      guts_header = 'cases = ['
      guts = ''
      agent.combinations.each do |combo|
        values = combo.map do |datum|
          case datum
          when Hash
            datum.first.last
          else
            datum
          end
        end
        guts << ",\n#{' ' * guts_header.length}" if !guts.empty?
        guts << "#{@struct_name}.new#{values.inspect.gsub(/\[/, '(').gsub(/\]/, ')')}"
      end
      @io.print(struct_header)
      @io.print(struct)
      @io.print("\n\n")
      @io.print(guts_header)
      @io.print(guts)
      @io.print("]\n")
    end
  end
end

if __FILE__ == $0
  sets = CLabs::CaseGen::Sets.new("a: 1, 2\nb: 3, 4")
  puts sets.combinations
end
