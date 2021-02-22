# frozen_string_literal: true

module CaseGen
  class ExpectRule
    include ComboMatcher

    def initialize(rule_data, _)
      @rule_data = rule_data
    end

    def apply(combos)
      combos.each do |combo|
        expect_keys = combo.names.select { |name| combo.send(name) == :expect }
        next if expect_keys.none?

        next unless matches_criteria(combo, expect_keys)

        expect_keys.each do |expect_key|
          combo.send("#{expect_key}=", @rule_data[expect_key])
        end
      end
    end
  end
end
