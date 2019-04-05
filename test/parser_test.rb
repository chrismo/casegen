$LOAD_PATH << "#{__dir__}/../lib"
require 'minitest/autorun'
require 'casegen'

include CLabs::CaseGen

class SampleAgent < Agent
  def SampleAgent.agent_id
    "sample"
  end
end

class Foo < Agent
  def Foo.agent_id
    "foo"
  end
end

class TestParser < Minitest::Test
  def setup
    Agents.instance.register(SampleAgent)
    Agents.instance.register(Foo)
  end

  def test_parse
    data = <<~CASEDATA
      sample
      ------
      sample_data
      
      foo
      ---
      sample_data
      
      sample(foo, sample)
      ------------
      sample_data
      plus
        some extra
    CASEDATA

    parser = Parser.new(data)
    assert_equal(3, parser.agents.length)

    sample_a = parser.agents[0]
    foo = parser.agents[1]
    sample_b = parser.agents[2]
    assert_equal(SampleAgent, sample_a.class)
    assert_equal("sample_data", sample_a.data)
    assert_equal([], sample_a.reference_agents)

    assert_equal(Foo, foo.class)
    assert_equal("sample_data", foo.data)
    assert_equal([], foo.reference_agents)

    assert_equal(SampleAgent, sample_b.class)
    assert_equal("sample_data\nplus\n  some extra", sample_b.data)
    assert_equal([foo, sample_a], sample_b.reference_agents)
  end

  def test_parse_no_sets
    data = <<~CASEDATA
    CASEDATA

    parser = Parser.new(data)
    assert_equal(0, parser.agents.length)
  end

  def test_parse_agent_with_missing_hyphen_line
    data = <<~CASEDATA
      sample
      
      sample_data
    CASEDATA

    Parser.new(data)
    fail("should have thrown")
  rescue ParserException => e
    assert_equal("Expected hyphen line after the agent declaration for <SampleAgent>", e.message)
  end

  def test_parse_agent_name_without_dash_delimiter
    data = <<~CASEDATA
      sample
    CASEDATA

    Parser.new(data)
    fail("should have thrown")
  rescue ParserException => e
    assert_equal("Expected hyphen line after the agent declaration for <SampleAgent>", e.message)
  end

  def test_parse_agent_name_without_dash_delimiter_and_empty_line_to_start
    data = <<~CASEDATA

      sample
    CASEDATA

    Parser.new(data)
    fail("should have thrown")
  rescue ParserException => e
    assert_equal("Expected hyphen line after the agent declaration for <SampleAgent>", e.message)
  end

  def test_parse_just_agent_with_underline
    data = <<~CASEDATA
      sample
      -
    CASEDATA

    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal("", sample.data)
    assert_equal([], sample.reference_agents)
  end

  def test_parse_just_agent_with_empty_data
    data = <<~CASEDATA
      sample
      -

    CASEDATA

    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal("", sample.data)
    assert_equal([], sample.reference_agents)
  end

  def test_parse_invalid_agent
    data = <<~CASEDATA
      sermple
      ------
      sample_data
    CASEDATA

    begin
      Parser.new(data)
      fail("should throw")
    rescue ParserException
      # expected
    end
  end

  def test_parse_invalid_referenced_agent
    data = <<~CASEDATA
      sample(fu)
      ------
      sample_data
    CASEDATA

    begin
      Parser.new(data)
      fail("should throw")
    rescue ParserException
      # expected
    end
  end
end