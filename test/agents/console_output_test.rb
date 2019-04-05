require_relative '../test_helper'
require_relative '../../lib/agents/sets.rb'

FakeAgent = Struct.new(:titles, :combinations)

include CLabs::CaseGen

class TestConsoleOutput < Minitest::Test
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
end
