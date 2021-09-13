# frozen_string_literal: true

module CaseGen
  class ExcludeAsTable < CaseGen::Output
    def exclude_output(exclude)
      "\n#{as_table(exclude)}"
    end

    def exclude_description(rule)
      rule.description
    end
  end
end
