# frozen_string_literal: true

require 'tablesmith'

module CaseGen
  class Generator
    attr_reader :sets, :rules, :combos, :exclusions

    def initialize(sets, rules)
      @sets = sets.map do |title, values|
        CaseGen::Set.new(title, values)
      end
      @rules = rules
      @combos = generate_combinations
      apply_rules
    end

    private

    def generate_combinations
      hash_pairs = @sets.map(&:hash_pairs)
      product_of(hash_pairs).map { |c| Combination.new(c) }
    end

    def product_of(sets)
      head, *rest = sets
      head.product(*rest)
    end

    def apply_rules
      @rules.each do |type, rules|
        klass = CaseGen.const_get("#{type.to_s.capitalize}Rule")
        rules.each_with_index do |rule_data, idx|
          rule_data[:index] = idx + 1
          klass.new(rule_data).apply(@combos)
        end
      end
    end
  end
end
