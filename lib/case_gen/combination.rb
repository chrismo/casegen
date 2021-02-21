# frozen_string_literal: true

module CaseGen
  class Combination
    attr_reader :names

    def initialize(hash_pairs)
      @names = hash_pairs.map do |h|
        k = h.first.first
        v = h.first.last
        append(k, v)
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

    def append(key, value)
      @names << key if defined?(@names)
      instance_variable_set("@#{key}", value)
      self.class.attr_accessor key
    end
  end
end
