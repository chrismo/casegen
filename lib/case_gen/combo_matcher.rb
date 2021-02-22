# frozen_string_literal: true

module CaseGen
  module ComboMatcher
    def matches_criteria(combo, additional_ignore_keys = [])
      criteria_keys = (@rule_data.keys - additional_ignore_keys) - ignore_keys
      criteria = @rule_data.slice(*criteria_keys)
      criteria == combo.hash_row.slice(*criteria_keys)
    end

    def ignore_keys
      %i[description reason note index]
    end
  end
end
