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
  def self.generate(sets, rules, output_options = [])
    generator = CaseGen::Generator.new(sets, rules, output_options)
    output = CaseGen::Output.new(generator)
    output_options.each do |opt|
      output.send("#{opt}=", true)
    end
    output.to_s
  end
end
