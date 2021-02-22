# frozen_string_literal: true

module CaseGen
  class Output
    include RuleDescription

    attr_accessor :exclude_as_text, :exclude_inline, :exclude_inline_footnotes,
                  :exclude_as_table

    def initialize(generator)
      @generator = generator
    end

    def to_s
      @generator.combos_table.to_s.tap do |o|
        o << exclude_rules_as_text if @exclude_as_text
        o << exclude_rules_inline_footnotes if @exclude_inline_footnotes
        o << exclude_rules_as_table if @exclude_as_table
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
      "\n#{@generator.exclusions_table.to_s}"
    end
  end
end
