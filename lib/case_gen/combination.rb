# frozen_string_literal: true

module CaseGen
  class Combination
    attr_reader :names

    def initialize(hash_pairs)
      @hash_pairs = hash_pairs
      @names = hash_pairs.map do |h|
        k = h.first.first
        v = h.first.last
        instance_variable_set("@#{k}", v)
        self.class.attr_accessor k
        k
      end
    end

    def hash_row
      {}.tap do |h|
        @names.each do |ivar|
          h[ivar] = instance_variable_get("@#{ivar}")
        end
      end
    end
  end
end
