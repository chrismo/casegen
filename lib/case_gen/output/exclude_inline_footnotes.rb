# frozen_string_literal: true

module CaseGen
  class ExcludeInlineFootnotes < CaseGen::Output
    def partition_exclusions?
      false
    end

    def exclude_description(rule)
      "[#{rule.rule_data[:index]}]"
    end

    def exclude_output(_)
      body = @generator.rules[:exclude].map do |rule|
        ["[#{rule[:index]}] #{rule_description(rule)}"]
      end
      (header + body).join("\n")
    end
  end
end
