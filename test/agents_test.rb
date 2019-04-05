$LOAD_PATH << "#{__dir__}/../lib"
require 'minitest/autorun'
require 'casegen'

include CLabs::CaseGen

class TestAgents < Minitest::Test
  def setup
    Agents.instance.clear
  end

  def teardown
    Agents.instance.clear
  end

  def test_register
    assert_equal(0, Agents.instance.length)
    begin
      Agents.instance.register("phil")
      fail("should have thrown")
    rescue AgentException
      # expected -- can't register a non subclass
    end

    Agents.instance.register(SampleAgent)
    assert_equal(1, Agents.instance.length)
    Agents.instance.each do |ag| assert_equal(SampleAgent, ag) end
  end

  def test_get_agent_by_id
    Agents.instance.register(SampleAgent)
    result = Agents.instance.get_agent_by_id("sample")
    assert_equal(SampleAgent, result)
  end

  def test_id_registered
    assert_equal(false, Agents.instance.id_registered?(SampleAgent.agent_id))
    Agents.instance.register(SampleAgent)
    assert_equal(true, Agents.instance.id_registered?(SampleAgent.agent_id))
  end
end
