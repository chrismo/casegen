# frozen_string_literal: true

module CaseGen
  class Output
    include RuleDescription

    def initialize(generator, output_type = :exclude)
      @generator = generator
      @output_type = output_type
    end

    def to_s
      update_excluded_values
      include, exclude = partition_exclusions

      as_table(include).tap do |o|
        o << exclude_rules_as_text if @output_type == :exclude_as_text
        o << exclude_rules_inline_footnotes if @output_type == :exclude_inline_footnotes
        o << "\n#{as_table(exclude)}" if @output_type == :exclude_as_table
      end
    end

    private

    def as_table(combos)
      combos.map(&:hash_row).to_table.to_s
    end

    def update_excluded_values
      @generator.combos.each do |combo|
        if combo.excluded?
          value = exclude_description(combo.excluded_by_rule)
          combo.append(:exclude, value)
        end
      end
    end

    def partition_exclusions
      combos = @generator.combos

      case @output_type
      when :exclude_as_table, :exclude, :exclude_as_text
        exclude, include = combos.partition(&:excluded?)
        [include, exclude]
      when :exclude_inline, :exclude_inline_footnotes
        [combos, []]
      end
    end

    def exclude_description(rule)
      case @output_type
      when :exclude_inline_footnotes
        "[#{rule.rule_data[:index]}]"
      when :exclude_inline, :exclude_as_table
        rule.description
      end
    end

    def exclude_rules_as_text
      body = @generator.rules[:exclude].map do |rule|
        [rule[:criteria], "  #{rule_description(rule)}", '']
      end
      (header + body).join("\n")
    end

    def header
      ['', 'exclude', '-------']
    end

    def exclude_rules_inline_footnotes
      body = @generator.rules[:exclude].map do |rule|
        ["[#{rule[:index]}] #{rule_description(rule)}"]
      end
      (header + body).join("\n")
    end
  end
end
