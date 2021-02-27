# frozen_string_literal: true

require_relative 'case_gen/rule_description'
require_relative 'case_gen/set'
require_relative 'case_gen/combo_matcher'
require_relative 'case_gen/exclude_rule'
require_relative 'case_gen/expect_rule'
require_relative 'case_gen/combination'
require_relative 'case_gen/generator'
require_relative 'case_gen/output'

module CaseGen
  def self.generate(sets, rules, output_type = :exclude)
    generator = CaseGen::Generator.new(sets, rules)
    CaseGen::Output.create(generator, output_type).to_s
  end
end
