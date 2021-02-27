# frozen_string_literal: true

module CaseGen
  class ExcludeInline < CaseGen::Output
    def partition_exclusions?
      false
    end

    def exclude_description(rule)
      rule.description
    end
  end
end
