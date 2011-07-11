$LOAD_PATH << "#{File.dirname(__FILE__)}/../src"
require 'test/unit'
require 'casegen'

include CLabs::CaseGen

class TestAgents < Test::Unit::TestCase
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

class TestParser < Test::Unit::TestCase
  def setup
    Agents.instance.register(SampleAgent)
    Agents.instance.register(Foo)
  end

  def test_parse
    data = <<-CASEDATA.outdent
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
    data = <<-CASEDATA.outdent
    CASEDATA

    parser = Parser.new(data)
    assert_equal(0, parser.agents.length)
  end

  def test_parse_agent_with_missing_hyphen_line
    data = <<-CASEDATA.outdent
      sample
      
      sample_data
    CASEDATA
  
    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal(nil, sample.data)
    assert_equal([], sample.reference_agents)
  end
  
  def test_parse_just_agent
    data = <<-CASEDATA.outdent
      sample
    CASEDATA
  
    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal(nil, sample.data)
    assert_equal([], sample.referenced_agents)
  end

  def test_parse_just_agent_with_underline
    data = <<-CASEDATA.outdent
      sample
      -
    CASEDATA

    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal(nil, sample.data)
    assert_equal([], sample.referenced_agents)
  end

  def test_parse_just_agent_with_empty_data
    data = <<-CASEDATA.outdent
      sample
      -

    CASEDATA

    parser = Parser.new(data)
    assert_equal(1, parser.agents.length)
    sample = parser.agents[0]
    assert_equal(SampleAgent, sample.class)
    assert_equal(nil, sample.data)
    assert_equal([], sample.referenced_agents)
  end

  def test_parse_invalid_agent
    data = <<-CASEDATA.outdent
      sermple
      ------
      sample_data
    CASEDATA
  
    begin
      parser = Parser.new(data)
      fail("should throw")
    rescue ParserException
      # expected
    end
  end
  
  def test_parse_invalid_referenced_agent
    data = <<-CASEDATA.outdent
      sample(fu)
      ------
      sample_data
    CASEDATA
  
    begin
      parser = Parser.new(data)
      fail("should throw")
    rescue ParserException
      # expected
    end
  end

  def test_parse_should_not_be_so_strict
    fail("change parser to allow empty agents")
  end
end
 
