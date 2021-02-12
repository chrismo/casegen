module CaseGen
  class Rule
    attr_reader :description, :criteria

    def initialize(description, criteria)
      @description = description
      @criteria = criteria
    end
  end
end