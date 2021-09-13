# frozen_string_literal: true

module CaseGen
  class ExcludeAsText < CaseGen::Output
    def exclude_output(_)
      body = @generator.rules[:exclude].map do |rule|
        [rule[:criteria], "  #{rule_description(rule)}", '']
      end
      (header + body).join("\n")
    end
  end
end
