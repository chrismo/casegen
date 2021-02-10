require_relative '../test_helper'
require_relative '../../lib/agents/sets.rb'

FakeAgent = Struct.new(:titles, :combinations)

class TestConsoleOutput < Minitest::Test
  include CLabs::CaseGen

  def test_simple_output
    data = nil
    agents = [
      FakeAgent.new(["col a", "col b"], [[1, 2], [3, 4]])
    ]
    sio = StringIO.new
    ConsoleOutput.new(data, agents, sio)
    expected = <<~_
      +-------+-------+
      | col a | col b |
      +-------+-------+
      | 1     | 2     |
      | 3     | 4     |
      +-------+-------+

    _
    assert_equal expected, sio.string
  end

  def test_hide_rule_output
    rule_show = TestRule.new("a = 1")
    rule_hide = TestRule.new("a = 2")
    rule_hide.instance_variable_set("@hide_output", true)

    rules = Rules.new("")

    def rules.titles
      %w[a b]
    end

    def rules.combinations
      [[1, 2]]
    end

    rules.instance_variable_set("@rules", [rule_show, rule_hide])

    sio = StringIO.new
    ConsoleOutput.new(nil, [rules], sio)
    expected = <<~_
      +---+---+
      | a | b |
      +---+---+
      | 1 | 2 |
      +---+---+

      a = 1


    _
    assert_equal expected, sio.string
  end
end

class TestRule < CLabs::CaseGen::Rule
  def self.regexp
    //
  end

  def self.create(_) end
end
