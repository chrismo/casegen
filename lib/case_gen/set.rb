# frozen_string_literal: true

module CaseGen
  class Set
    attr_reader :title, :values

    def initialize(title, values)
      @title = title
      @values = values
    end

    def hash_pairs
      @values.map { |v| {@title => v} }
    end
  end
end
