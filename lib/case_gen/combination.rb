module CaseGen
  class Combination
    def initialize(hash_pairs)
      @hash_pairs = hash_pairs
      hash_row.each do |k, v|
        instance_variable_set("@#{k}", v)
        self.class.attr_reader k
      end
    end

    def hash_row
      @hash_row ||=
        @hash_pairs.reduce({}) { |pair, h| pair.merge(h) }
    end
  end
end