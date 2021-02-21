# frozen_string_literal: true

module CaseGen
  class ExpectRule
    def initialize(rule_data, options = [])
      @rule_data = rule_data
      @ignore_keys = %i[description reason note]
      @options = options
    end

    def apply(combos)
      combos.each do |combo|
        expect_keys = combo.names.select { |name| combo.send(name) == :expect }
        next if expect_keys.none?

        criteria_keys = (@rule_data.keys - expect_keys) - @ignore_keys
        criteria = @rule_data.slice(*criteria_keys)

        next unless criteria == combo.hash_row.slice(*criteria_keys)

        expect_keys.each do |expect_key|
          combo.send("#{expect_key}=", @rule_data[expect_key])
        end
      end
    end
  end
end
