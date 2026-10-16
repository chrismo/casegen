# frozen_string_literal: true

require 'delegate'
require 'json'
require_relative '../lib/casegen'

class Fixtures
  class << self
    attr_reader :fixtures

    def add(name, sets, rules)
      @fixtures ||= {}
      @fixtures[name] = {sets: sets, rules: {exclude: []}.merge(rules)}
    end
  end
end

%w[cart pricing bounding_box expect_only].each do |example|
  require_relative "../doc/#{example}"
end

formats = %i[exclude exclude_as_table exclude_inline exclude_inline_footnotes]
result = Fixtures.fixtures.transform_values do |fixture|
  formats.to_h do |format|
    [format, CaseGen.generate(fixture[:sets], fixture[:rules], format)]
  end
end
pricing = Fixtures.fixtures[:pricing]
result[:pricing][:exclude_as_text] = CaseGen.generate(pricing[:sets], pricing[:rules], :exclude_as_text)
puts JSON.pretty_generate(result)
