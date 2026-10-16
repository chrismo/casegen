import copy
import importlib
import json
from pathlib import Path
import unittest

from casegen import (
    EXPECT,
    Combination,
    ExcludeRule,
    ExpectRule,
    Generator,
    Output,
    combinations,
    generate,
)


class RubyParityTests(unittest.TestCase):
    def test_all_examples_and_output_formats(self):
        fixtures = json.loads(
            (Path(__file__).parent / "fixtures" / "ruby_outputs.json").read_text()
        )
        modules = {
            "cart": "cart",
            "pricing": "pricing",
            "box": "bounding_box",
            "duration": "expect_only",
        }
        for name, formats in fixtures.items():
            example = importlib.import_module(f"doc.{modules[name]}")
            for output_type, expected in formats.items():
                with self.subTest(example=name, output_type=output_type):
                    if output_type == "exclude_as_text":
                        expected = expected.replace("&&", "and")
                    self.assertEqual(
                        generate(example.sets, example.rules, output_type), expected
                    )


class CombinationTests(unittest.TestCase):
    def test_append_and_read_values(self):
        combo = Combination({"a": 1, "b": 2})
        combo.append("c", 3)
        combo.append("a", 4)
        self.assertEqual(combo.hash_row(), {"a": 4, "b": 2, "c": 3})
        self.assertEqual(combo.names, ["a", "b", "c"])
        self.assertEqual(combo.a, 4)
        self.assertEqual(combo["c"], 3)

    def test_dimensions_do_not_leak_between_instances(self):
        first = Combination({"a": 1})
        second = Combination({"b": 2})
        self.assertEqual(first.a, 1)
        with self.assertRaises(AttributeError):
            _ = second.a

    def test_item_access_supports_method_names_and_spaces(self):
        combo = Combination({"names": 1, "a b": 2})
        self.assertEqual(combo["names"], 1)
        self.assertEqual(combo["a b"], 2)

    def test_hash_row_is_a_copy(self):
        combo = Combination({"a": 1})
        combo.hash_row()["a"] = 2
        self.assertEqual(combo.a, 1)


class RuleTests(unittest.TestCase):
    def test_exclude_accepts_expressions_callables_and_key_values(self):
        criteria = [
            {"criteria": "a == 1"},
            {"criteria": lambda c: c.a == 1},
            {"criteria": lambda c: c["a"] == 1},
            {"a": 1},
            {"a": 1, "criteria": None},
        ]
        for data in criteria:
            with self.subTest(data=data):
                combos = [Combination({"a": 1}), Combination({"a": 2})]
                rule = ExcludeRule(data)
                rule.apply(combos)
                self.assertIs(combos[0].excluded_by_rule, rule)
                self.assertFalse(combos[1].excluded)

    def test_metadata_does_not_affect_matching(self):
        combo = Combination({"a": 1})
        ExcludeRule(
            {
                "a": 1,
                "reason": "reason",
                "note": "note",
                "description": "description",
                "index": 7,
            }
        ).apply([combo])
        self.assertTrue(combo.excluded)
        self.assertEqual(combo.excluded_by_rule.description, "reason")

    def test_unknown_dimension_does_not_match_even_for_none(self):
        combo = Combination({"a": 1})
        ExcludeRule({"typo": None}).apply([combo])
        self.assertFalse(combo.excluded)

    def test_first_exclusion_wins(self):
        generator = Generator(
            {"a": [1]}, {"exclude": [{"note": "first"}, {"note": "second"}]}
        )
        self.assertEqual(generator.combos[0].excluded_by_rule.description, "first")

    def test_exclusion_clears_pending_expects_but_not_literal_strings(self):
        combo = Combination({"a": 1, "b": EXPECT, "c": "expect"})
        ExcludeRule({"a": 1}).apply([combo])
        self.assertEqual(combo.hash_row(), {"a": 1, "b": "", "c": "expect"})

    def test_expect_fills_multiple_pending_columns(self):
        combo = Combination({"a": 1, "b": EXPECT, "c": EXPECT})
        ExpectRule({"a": 1, "b": 2, "c": 3, "note": "metadata"}).apply([combo])
        self.assertEqual(combo.hash_row(), {"a": 1, "b": 2, "c": 3})

    def test_first_expect_assignment_wins(self):
        rows = combinations(
            {"a": [1], "b": [EXPECT]},
            {"expect": [{"a": 1, "b": 2}, {"a": 1, "b": 3}]},
        )
        self.assertEqual(rows, [{"a": 1, "b": 2}])

    def test_missing_expect_assignment_remains_visible(self):
        rows = combinations({"a": [1], "b": [EXPECT]}, {"expect": [{"a": 2, "b": 3}]})
        self.assertIs(rows[0]["b"], EXPECT)

    def test_missing_expect_output_value_becomes_none(self):
        self.assertEqual(
            combinations({"a": [1], "b": [EXPECT]}, {"expect": [{"a": 1}]}),
            [{"a": 1, "b": None}],
        )

    def test_invalid_criteria_is_rejected(self):
        for criteria in (1, [], {}):
            with self.subTest(criteria=criteria), self.assertRaises(TypeError):
                ExcludeRule({"criteria": criteria})

    def test_invalid_expression_is_not_silently_ignored(self):
        with self.assertRaises(SyntaxError):
            ExcludeRule({"criteria": "a =="})
        with self.assertRaises(NameError):
            Generator({"a": [1]}, {"exclude": [{"criteria": "typo == 1"}]})

    def test_expression_can_use_python_operations_and_builtins(self):
        self.assertEqual(
            combinations(
                {"a": ["x", "long"]},
                {"exclude": [{"criteria": "len(a) > 1 or a is None"}]},
            ),
            [{"a": "x"}],
        )


class GeneratorTests(unittest.TestCase):
    def test_product_order_and_optional_rules(self):
        self.assertEqual(
            combinations({"a": [1, 2], "b": ["x", "y"]}),
            [
                {"a": 1, "b": "x"},
                {"a": 1, "b": "y"},
                {"a": 2, "b": "x"},
                {"a": 2, "b": "y"},
            ],
        )

    def test_values_can_be_iterables(self):
        self.assertEqual(combinations({"a": iter([1, 2])}), [{"a": 1}, {"a": 2}])

    def test_exclude_runs_before_expect_regardless_of_rule_order(self):
        rules = {"expect": [{"a": 1, "b": 2}], "exclude": [{"a": 1}]}
        generator = Generator({"a": [1], "b": [EXPECT]}, rules)
        self.assertEqual(generator.rows(), [])
        self.assertEqual(generator.rows(include_excluded=True), [{"a": 1, "b": ""}])

    def test_input_and_output_containers_are_not_mutated(self):
        sets = {"a": [1, 2], "b": [EXPECT]}
        rules = {"exclude": [{"a": 2, "note": "nope"}], "expect": [{"a": 1, "b": 3}]}
        original_sets, original_rules = copy.deepcopy(sets), copy.deepcopy(rules)
        generator = Generator(sets, rules)
        generate(sets, rules, "exclude_inline_footnotes")
        self.assertEqual(sets, original_sets)
        self.assertEqual(rules, original_rules)
        generator.rows()[0]["a"] = 99
        self.assertEqual(generator.rows()[0]["a"], 1)

    def test_empty_dimension_has_no_combinations(self):
        self.assertEqual(combinations({"a": []}), [])

    def test_empty_sets_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "At least one set"):
            Generator({})

    def test_unknown_rule_type_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown rule type"):
            Generator({"a": [1]}, {"typo": []})


class OutputTests(unittest.TestCase):
    def test_rendering_is_repeatable_and_does_not_mutate_combinations(self):
        generator = Generator({"a": [1, 2]}, {"exclude": [{"a": 1, "note": "nope"}]})
        original = generator.rows(include_excluded=True)
        outputs = {}
        formats = [
            "exclude",
            "exclude_as_table",
            "exclude_as_text",
            "exclude_inline",
            "exclude_inline_footnotes",
        ]
        for output_type in formats * 2:
            output = Output.create(generator, output_type)
            rendered = str(output)
            self.assertEqual(str(output), rendered)
            self.assertEqual(outputs.setdefault(output_type, rendered), rendered)
        self.assertEqual(generator.rows(include_excluded=True), original)

    def test_unknown_output_type_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown output type"):
            generate({"a": [1]}, output_type="typo")

    def test_empty_table(self):
        self.assertEqual(generate({"a": []}), "+---------+\n| (empty) |\n+---------+\n")
        self.assertEqual(generate({"a": [1]}, {"exclude": [{}]}), generate({"a": []}))

    def test_exclusion_formats_work_without_exclusion_rules(self):
        for output_type in ("exclude_as_text", "exclude_inline_footnotes"):
            with self.subTest(output_type=output_type):
                self.assertTrue(
                    generate({"a": [1]}, output_type=output_type).endswith(
                        "\nexclude\n-------"
                    )
                )

    def test_text_output_omits_unstable_callable_representations(self):
        output = generate(
            {"a": [1]},
            {"exclude": [{"criteria": lambda c: True, "note": "nope"}]},
            "exclude_as_text",
        )
        self.assertIn("  nope", output)
        self.assertNotIn("lambda", output)
        self.assertNotIn("0x", output)

    def test_boolean_none_and_literal_expect_rendering(self):
        self.assertEqual(
            generate({"a": [True, False, None, EXPECT, "expect"]}),
            "+--------+\n|   a    |\n+--------+\n| true   |\n| false  |\n|        |\n| expect |\n| expect |\n+--------+\n",
        )


if __name__ == "__main__":
    unittest.main()
