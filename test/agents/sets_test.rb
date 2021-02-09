$LOAD_PATH << "#{__dir__}/../../lib/agents"
require 'minitest/autorun'
require 'sets'

class TestParsing < Minitest::Test
  include CLabs::CaseGen

  def test_sets_default
    data = <<~CASEDATA
      bar: 1, 2, 3,456.98
       foo list:a, b, c
    CASEDATA
    cases = Sets.new(data)
    assert_equal(2, cases.sets.length)

    assert_equal("bar", cases.sets[0].name)
    assert_equal(%w[1 2 3,456.98], cases.sets[0].data)

    assert_equal("foo list", cases.sets[1].name)
    assert_equal(%w[a b c], cases.sets[1].data)
  end

  def test_set_by_name_matching
    # may seem obvious, but the regex matching used at one point would get confused when a name was reused in sets
    sets = Sets.new("foo bar: 1, 2\nbar quux: 3, 4")
    set = sets.set_by_name('bar quux')
    assert_equal 'bar quux', set.name
  end

  def test_expect_set
    data = <<~CASEDATA
      bar: 1, 2, 3,456.98
       foo list:a, b, c
      expect:
    CASEDATA

    cases = Sets.new(data)
    assert_equal(3, cases.sets.length)

    assert_equal("expect", cases.sets.last.name)
    assert_equal([], cases.sets.last.data)
  end
end

class TestCombinations < Minitest::Test
  include CLabs::CaseGen

  def test_combos_2_by_2
    sets = Sets.new("a: 1, 2\nb:3, 4")
    assert_equal([
                   [{"a" => "1"}, {"b" => "3"}],
                   [{"a" => "1"}, {"b" => "4"}],
                   [{"a" => "2"}, {"b" => "3"}],
                   [{"a" => "2"}, {"b" => "4"}]
                 ], sets.combinations)
    assert_equal(%w[a b], sets.titles)
  end

  def test_combos_2_by_3
    sets = Sets.new("a: 1, 2\nb:3, 4, 5")
    assert_equal([
                   [{"a" => "1"}, {"b" => "3"}],
                   [{"a" => "1"}, {"b" => "4"}],
                   [{"a" => "1"}, {"b" => "5"}],
                   [{"a" => "2"}, {"b" => "3"}],
                   [{"a" => "2"}, {"b" => "4"}],
                   [{"a" => "2"}, {"b" => "5"}]
                 ], sets.combinations)
    assert_equal(%w[a b], sets.titles)
  end

  def test_expect_combos
    sets = Sets.new("a: 1, 2\nb:3, 4, 5\nexpect:")
    assert_equal(%w[a b expect], sets.titles)
    assert_equal([
                   [{"a" => "1"}, {"b" => "3"}, {"expect" => ""}],
                   [{"a" => "1"}, {"b" => "4"}, {"expect" => ""}],
                   [{"a" => "1"}, {"b" => "5"}, {"expect" => ""}],
                   [{"a" => "2"}, {"b" => "3"}, {"expect" => ""}],
                   [{"a" => "2"}, {"b" => "4"}, {"expect" => ""}],
                   [{"a" => "2"}, {"b" => "5"}, {"expect" => ""}]
                 ], sets.combinations)
  end
end

class TestRulesParsing < Minitest::Test
  include CLabs::CaseGen

  def test_rules_single
    data = <<~RULES
      exclude foo = bar
    RULES
    rules = Rules.new(data)
    assert_equal(1, rules.length)
    assert_equal(ExcludeRule, rules[0].class)
    assert_equal("foo = bar", rules[0].criteria.to_s)
    assert_equal("", rules[0].description)
  end

  def test_rules_two
    data = <<~RULES
      exclude foo = bar
        should foo equal bar, we want to exclude that combination
      
      exclude bar = foo
        as well, if bar equals foo,
        that case has got to go
    RULES
    rules = Rules.new(data)
    assert_equal(2, rules.length)
    assert_equal(ExcludeRule, rules[0].class)
    assert_equal("foo = bar", rules[0].criteria.to_s)
    assert_equal("should foo equal bar, we want to exclude that combination", rules[0].description)

    assert_equal(ExcludeRule, rules[1].class)
    assert_equal("bar = foo", rules[1].criteria.to_s)
    assert_equal("as well, if bar equals foo,\nthat case has got to go", rules[1].description)
  end

  def test_exclude_rule_parsing
    data = <<~RULES
      exclude foo = bar
        should foo equal bar, we want to exclude that combination
    RULES
    rule = ExcludeRule.new(data)
    assert_equal("foo = bar", rule.criteria.to_s)
    assert_equal(["foo"], rule.criteria.set_names)
    assert_equal(["bar"], rule.criteria.set_values)
    assert_equal("should foo equal bar, we want to exclude that combination", rule.description)

  end

  def test_rules_set_name_not_found
    sets = Sets.new("set.a: foo, bar\nset.b: fu, bahr")
    data = <<~RULES
      exclude set_a = bar AND set_b = barh
        should foo equal bar, we want to exclude that combination
    RULES
    begin
      Rules.new(data, [sets])
      fail('should throw')
    rescue ParserException => e
      assert_equal("Invalid set name <set_a> in rule <set_a = bar AND set_b = barh>. Valid set names are <set.a, set.b>.", e.message)
    end
  end

  def test_rules_set_value_not_found
    sets = Sets.new("set a: foo, bar\nset b: fu, bahr")
    data = <<~RULES
      exclude set a = bar AND set b = barh
        should foo equal bar, we want to exclude that combination
    RULES
    begin
      Rules.new(data, [sets])
      fail('should throw')
    rescue ParserException => e
      assert_equal("Invalid set value <barh> in rule <set a = bar AND set b = barh>. Valid set values for <set b> are <fu, bahr>.", e.message)
    end
  end

  class TestCriteria < Minitest::Test
    include CLabs::CaseGen

    def test_simple_equality
      crit = Criteria.new("a = b")
      assert_equal(['a'], crit.set_names)
      assert_equal(['b'], crit.set_values)
      assert_equal(true, crit.match({'a' => 'b'}))
      assert_equal(false, crit.match({'a' => 'c'}))
      assert_equal(false, crit.match({'b' => 'a'}))
      assert_equal(true, crit.match({'a' => 'b', 'f' => 'g'}))
    end

    def test_boolean_and
      crit = Criteria.new("a = b AND c == d")
      assert_equal(%w[a c], crit.set_names)
      assert_equal(%w[b d], crit.set_values)
      assert_equal(true, crit.match({'a' => 'b', 'c' => 'd'}))
      assert_equal(false, crit.match({'a' => 'd', 'c' => 'b'}))
      assert_equal(true, crit.match({'c' => 'd', 'a' => 'b'}))
      assert_equal(false, crit.match({'a' => 'b'}))
      assert_equal(false, crit.match({'c' => 'd'}))
      assert_equal(false, crit.match({'a' => 'b', 'd' => 'c'}))
      assert_equal(false, crit.match({'c' => 'd', 'b' => 'a'}))

      # not case sensitive
      assert_equal(false, crit.match({'A' => 'b', 'c' => 'd'}))
      assert_equal(false, crit.match({'a' => 'B', 'c' => 'd'}))
      assert_equal(false, crit.match({'a' => 'b', 'C' => 'd'}))
      assert_equal(false, crit.match({'a' => 'b', 'c' => 'D'}))
    end

    def test_invalid_boolean_and
      begin
        Criteria.new("a = b AND a = d")
        fail("should throw")
      rescue ParserException => e
        assert_equal("Rule cannot have the same set <a> equal to different values <b, d>", e.message)
      end

      begin
        Criteria.new("a = b AND a = d AND a = c")
        fail("should throw")
      rescue ParserException => e
        # in this case, the exception is figured out before the a = c can be parsed
        assert_equal("Rule cannot have the same set <a> equal to different values <b, d>", e.message)
      end
    end
  end

  class TestRulesOnSets < Minitest::Test
    include CLabs::CaseGen

    def test_simple
      sets = Sets.new("a: 1, 2\nb: 3, 4")
      rules = Rules.new("exclude a = 1\nexclude b=4", [sets])
      assert_equal([%w[2 3]], rules.combinations)
      assert_equal(%w[a b], rules.titles)
    end
  end

  class TestRubyCaseArray < Minitest::Test
    include CLabs::CaseGen

    def test_default_case_name
      sets = Sets.new("a: 1, 2\nb:3, 4")
      out = MockStdOut.new
      RubyArrayOutput.new("", [sets], out)
      expected = <<~TEXT
        Case = Struct.new(:a, :b)

        cases = [Case.new("1", "3"),
                 Case.new("1", "4"),
                 Case.new("2", "3"),
                 Case.new("2", "4")]
      TEXT
      assert_equal(expected, out.to_s)
    end

    def test_specified_case_name
      sets = Sets.new("a: 1, 2\nb:3, 4")
      out = MockStdOut.new
      RubyArrayOutput.new("DataSubmitCase", [sets], out)
      expected = <<~TEXT
        DataSubmitCase = Struct.new(:a, :b)

        cases = [DataSubmitCase.new("1", "3"),
                 DataSubmitCase.new("1", "4"),
                 DataSubmitCase.new("2", "3"),
                 DataSubmitCase.new("2", "4")]
      TEXT
      assert_equal(expected, out.to_s)
    end
  end

  class MockStdOut
    def initialize
      @s = ''
    end

    def puts(s)
      @s << s << "\n"
    end

    def print(s)
      @s << s
    end

    def to_s
      @s
    end
  end
end
