# frozen_string_literal: true

module CaseGen
  module RuleDescription
    def rule_description(rule)
      keys = %i[description note reason]
      key = (rule.keys & keys).first
      rule[key]
    end
  end
end
