# frozen_string_literal: true

module CaseGen
  class ExcludeRule
    include RuleDescription

    def initialize(rule_data, options = [])
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
        else
          raise "Unknown rule criteria class: #{@criteria.class}"
        end
      end

      process_matches(combos, matches)
    end

    private

    def process_matches(combos, matches)
      if @options.include?(:exclude_inline)
        process_exclude_inline_matches(combos, matches)
      else
        combos.delete_if { |combo| matches.include?(combo) }
      end
    end

    # CANDO: replace conditional with polymorphism
    def process_exclude_inline_matches(combos, matches)
      combos.each do |combo|
        next unless matches.include?(combo)
        next if combo.names.include?(:exclude)

        combo.append(:exclude, @description)
        expect_keys = combo.names.select { |name| combo.send(name) == :expect }
        expect_keys.each do |expect_key|
          combo.send("#{expect_key}=", '')
        end
      end
    end
  end
end
