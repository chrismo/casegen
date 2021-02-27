# frozen_string_literal: true

module CaseGen
  class Output
    def self.create(generator, output_type = :exclude)
      klass_name = output_type.to_s.split('_').map(&:capitalize).join.to_s
      Object.const_get("CaseGen::#{klass_name}").new(generator)
    end

    include RuleDescription

    def initialize(generator)
      @generator = generator
    end

    def to_s
      update_excluded_values
      include, exclude = partition_exclusions
      as_table(include).tap { |o| o << exclude_output(exclude) }
    end

    private

    def exclude_output(_exclude)
      ''
    end

    def as_table(combos)
      combos.map(&:hash_row).to_table.to_s
    end

    def update_excluded_values
      @generator.combos.each do |combo|
        if combo.excluded?
          value = exclude_description(combo.excluded_by_rule)
          combo.append(:exclude, value)
        end
      end
    end

    def partition_exclusions
      combos = @generator.combos

      if partition_exclusions?
        exclude, include = combos.partition(&:excluded?)
        [include, exclude]
      else
        [combos, []]
      end
    end

    def partition_exclusions?
      true
    end

    def exclude_description(_rule)
      nil
    end

    def header
      ['', 'exclude', '-------']
    end
  end
end

Dir[File.join(__dir__, 'output', '*.rb')].sort.each { |fn| require fn }
