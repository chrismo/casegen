# frozen_string_literal: true

module CaseGen
  class Output
    include RuleDescription

    def initialize(generator, output_type = :exclude)
      @generator = generator
      @output_type = output_type
    end

    def to_s
      @generator.combos_table.to_s.tap do |o|
        o << exclude_rules_as_text if exclude_as_text
        o << exclude_rules_inline_footnotes if exclude_inline_footnotes
        o << exclude_rules_as_table if exclude_as_table
      end
    end

    private

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

    def exclude_rules_as_table
      "\n#{@generator.exclusions_table}"
    end

    def exclude_as_text
      @output_type == :exclude_as_text
    end

    def exclude_inline
      @output_type == :exclude_inline
    end

    def exclude_inline_footnotes
      @output_type == :exclude_inline_footnotes
    end

    def exclude_as_table
      @output_type == :exclude_as_table
    end
  end
end
