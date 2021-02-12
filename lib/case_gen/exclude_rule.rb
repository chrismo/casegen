module CaseGen
  class ExcludeRule
    def initialize(rule, combos)
      @rule = rule
      @combos = combos
    end

    def apply
      @combos.delete_if do |combo|
        criteria = @rule.criteria
        case criteria
        when String
          combo.instance_eval(criteria)
        when Proc
          combo.instance_exec(&criteria)
        else
          raise "Unknown rule criteria class: #{criteria.class}"
        end
      end
    end
  end
end