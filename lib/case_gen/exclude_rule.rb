# frozen_string_literal: true

module CaseGen
  class ExcludeRule
    include ComboMatcher
    include RuleDescription

    def initialize(rule_data, options = [])
      @rule_data = rule_data
      @description = rule_description(rule_data)
      @criteria = rule_data[:criteria]
      @options = options
    end

    def apply(combos)
      matches = combos.select do |combo|
        case @criteria
        when String
          combo.instance_eval(@criteria)
        when Proc
          combo.instance_exec(&@criteria)
        when nil
          # if the rule data has keys matching the combo, then compare the
          # values of provided keys.
          matches_criteria(combo)
        else
          raise "Unknown rule criteria class: #{@criteria.class}"
        end
      end

      process_matches(combos, matches)
    end

    private

    def process_matches(combos, matches)
      combos.each do |combo|
        next unless matches.include?(combo)
        next if combo.names.include?(:exclude)

        combo.append(:exclude, exclude_description)
        expect_keys = combo.names.select { |name| combo.send(name) == :expect }
        expect_keys.each do |expect_key|
          combo.send("#{expect_key}=", '')
        end
      end
    end

    def exclude_description
      if @options.include?(:exclude_inline_footnotes)
        "[#{@rule_data[:index]}]"
      elsif @options.include?(:exclude_inline) || @options.include?(:exclude_as_table)
        @description
      end
    end
  end
end
