from enum import Enum
from itertools import product


class _Marker(Enum):
    EXPECT = "expect"

    def __str__(self):
        return self.value


EXPECT = _Marker.EXPECT
_METADATA = {"description", "reason", "note", "index"}


def rule_description(rule):
    return next(
        (value for key, value in rule.items() if key in _METADATA - {"index"}), None
    )


class Combination:
    def __init__(self, values):
        self._values = dict(values)
        self.excluded_by_rule = None

    @property
    def names(self):
        return list(self._values)

    @property
    def excluded(self):
        return self.excluded_by_rule is not None

    def __getitem__(self, key):
        return self._values[key]

    def __getattr__(self, name):
        try:
            return self._values[name]
        except KeyError:
            raise AttributeError(name) from None

    def hash_row(self):
        return self._values.copy()

    def append(self, key, value):
        self._values[key] = value

    def exclude_with(self, rule):
        self.excluded_by_rule = rule


def _matches(combo, rule, ignored=()):
    return all(
        key in combo.names and combo[key] == value
        for key, value in rule.items()
        if key not in _METADATA and key not in ignored
    )


class ExcludeRule:
    def __init__(self, rule_data):
        self.rule_data = dict(rule_data)
        self.description = rule_description(rule_data)
        self.criteria = rule_data.get("criteria")
        self._expression = None
        if isinstance(self.criteria, str):
            self._expression = compile(self.criteria, "<casegen criteria>", "eval")
        elif self.criteria is not None and not callable(self.criteria):
            raise TypeError("Rule criteria must be a Python expression or callable")

    def apply(self, combos):
        for combo in combos:
            if combo.excluded:
                continue
            if self._expression is not None:
                matches = eval(self._expression, {}, combo.hash_row())
            elif callable(self.criteria):
                matches = self.criteria(combo)
            else:
                matches = _matches(combo, self.rule_data, {"criteria"})
            if matches:
                combo.exclude_with(self)
                for key in combo.names:
                    if combo[key] is EXPECT:
                        combo.append(key, "")


class ExpectRule:
    def __init__(self, rule_data):
        self.rule_data = dict(rule_data)

    def apply(self, combos):
        for combo in combos:
            if combo.excluded:
                continue
            keys = [key for key in combo.names if combo[key] is EXPECT]
            if keys and _matches(combo, self.rule_data, keys):
                for key in keys:
                    combo.append(key, self.rule_data.get(key))


class Generator:
    def __init__(self, sets, rules=None):
        if not sets:
            raise ValueError("At least one set is required")
        self.sets = {key: list(values) for key, values in sets.items()}
        self.rules = {
            kind: [dict(rule, index=index) for index, rule in enumerate(items, 1)]
            for kind, items in (rules or {}).items()
        }
        unknown = self.rules.keys() - {"exclude", "expect"}
        if unknown:
            raise ValueError(f"Unknown rule type: {', '.join(sorted(unknown))}")
        self.combos = [
            Combination(zip(self.sets, values))
            for values in product(*self.sets.values())
        ]
        for kind, rule_class in (("exclude", ExcludeRule), ("expect", ExpectRule)):
            for rule in self.rules.get(kind, []):
                rule_class(rule).apply(self.combos)

    def rows(self, *, include_excluded=False):
        """Return row copies, without output-format annotations."""
        return [
            combo.hash_row()
            for combo in self.combos
            if include_excluded or not combo.excluded
        ]
