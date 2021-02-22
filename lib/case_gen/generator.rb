# frozen_string_literal: true

require 'tablesmith'

module CaseGen
  class Generator
    attr_reader :sets, :rules, :combos, :exclusions

    def initialize(sets, rules, output_type = :exclude)
      @sets = sets.map do |title, values|
        CaseGen::Set.new(title, values)
      end
      @rules = rules
      @output_type = output_type
      @combos = generate_combinations
      process_rules
    end

    def combos_table
      @combos.map(&:hash_row).to_table
    end

    def exclusions_table
      @exclusions.map(&:hash_row).to_table
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

    def process_rules
      apply_rules
      process_exclusions
    end

    def apply_rules
      @rules.each do |type, rules|
        klass = CaseGen.const_get("#{type.to_s.capitalize}Rule")
        rules.each_with_index do |rule_data, idx|
          rule_data[:index] = idx + 1
          klass.new(rule_data, @output_type).apply(@combos)
        end
      end
    end

    def process_exclusions
      return if @output_type == :exclude_inline
      return if @output_type == :exclude_inline_footnotes

      exclude, include = @combos.partition { |combo| combo.names.include?(:exclude) }

      @combos = include
      @exclusions = @output_type == :exclude_as_table ? exclude : []
    end
  end
end
