# frozen_string_literal: true

module CaseGen
  class ExcludeRule
    def initialize(rule_data)
      @description = rule_data[:description]
      @criteria = rule_data[:criteria]
    end

    def apply(combos)
      combos.delete_if do |combo|
        case @criteria
        when String
          combo.instance_eval(@criteria)
        when Proc
          combo.instance_exec(&@criteria)
        else
          raise "Unknown rule criteria class: #{@criteria.class}"
        end
      end
    end
  end
end
