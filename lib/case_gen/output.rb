module CaseGen
  class Output
    attr_accessor :exclude_as_text

    def initialize(generator)
      @generator = generator
    end

    def to_s
      @generator.combos_table.to_s.tap do |o|
        o << exclude_rules_as_text if @exclude_as_text
      end
    end

    private

    def exclude_rules_as_text
      header = ['', 'exclude', '-------']
      body = @generator.rules[:exclude].map do |rule|
        [rule[:criteria], "  #{rule_description(rule)}", '']
      end
      (header + body).join("\n")
    end

    def rule_description(rule)
      keys = %i[description note reason]
      key = (rule.keys & keys).first
      rule[key]
    end
  end
end
