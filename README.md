# CaseGen — Python port

CaseGen generates combinations of variables, optionally restricted by rules,
with expected results and readable tables.

**`casegen-py` is a standalone, long-lived branch, not intended to merge into
`main`.** The [Ruby gem remains on `main`](https://github.com/chrismo/casegen/tree/main).
The original Ruby files are retained here as reference material; the Python
package does not depend on Ruby.

## Install

Python 3.10+; no runtime dependencies.

```sh
python -m pip install .
```

Or, for local development with [uv](https://docs.astral.sh/uv/):

```sh
uv sync
```

## Usage

```python
from casegen import EXPECT, combinations, generate

sets = {
    "role": ["admin", "standard"],
    "authorization": ["none", "valid"],
    "can_submit": [EXPECT],
}
rules = {
    "exclude": [
        {
            "role": "admin",
            "authorization": "none",
            "reason": "Admins always have authorization",
        },
    ],
    "expect": [
        {"role": "admin", "can_submit": True},
        {"role": "standard", "authorization": "none", "can_submit": False},
        {"role": "standard", "authorization": "valid", "can_submit": True},
    ],
}

print(generate(sets, rules))
# +----------+---------------+------------+
# |   role   | authorization | can_submit |
# +----------+---------------+------------+
# | admin    | valid         | true       |
# | standard | none          | false      |
# | standard | valid         | true       |
# +----------+---------------+------------+

rows = combinations(sets, rules)
assert rows[0] == {"role": "admin", "authorization": "valid", "can_submit": True}
```

Sets are dictionaries of dimension names to iterables of values. Combinations
follow set insertion order, with the last dimension varying fastest. At least
one set is required; an empty dimension produces no combinations. Rules are
optional.

### Exclusion rules

An exclusion can match key/value pairs, a callable receiving a combination, or
a Python expression using dimension names:

```python
{"role": "admin", "reason": "No admin cases"}
{"criteria": lambda c: c.role == "admin", "note": "No admin cases"}
{"criteria": "role == 'admin'", "description": "No admin cases"}
```

Use `c["dimension"]` for names containing spaces or colliding with combination
attributes such as `names`. String expressions use Python syntax (`and`, `or`,
`not`), not Ruby syntax.

**String criteria execute Python code via `eval`; they are not sandboxed. Only
use trusted rule definitions.** Callables are usually easier to debug.

`description`, `reason`, `note`, and `index` are rule metadata, not matching
criteria. The first supplied description/reason/note in dictionary order is
used for display. With overlapping exclusions, the first matching rule wins.

### Expected results

Use the exported `EXPECT` sentinel in a dimension's values to mark an output
column. Expect rules match the other dimensions and fill pending output columns.
The literal string `"expect"` is an ordinary value, not the sentinel.

Exclusions always run before expectations, regardless of dictionary order.
Excluded rows have pending expectations cleared. The first assignment to a
pending column wins; unmatched columns retain `EXPECT`, displayed as `expect`,
so gaps remain visible. There is no completeness validation.

### Output formats

`generate(sets, rules, output_type="exclude")` returns a string:

| `output_type` | Behavior |
| --- | --- |
| `exclude` | Show valid combinations only (default) |
| `exclude_as_table` | Show valid and excluded combinations in separate tables |
| `exclude_as_text` | Show valid combinations followed by exclusion rules |
| `exclude_inline` | Show all combinations with exclusion descriptions |
| `exclude_inline_footnotes` | Show all combinations with numbered exclusion notes |

Callable criteria are omitted from text output rather than rendered as unstable
function representations; their descriptions are still shown. Rendering does
not modify combinations or caller-owned rule dictionaries.

For structured data, `combinations(sets, rules)` returns a list of dictionaries
for valid combinations. For more control:

```python
from casegen import Generator, Output

generator = Generator(sets, rules)
all_rows = generator.rows(include_excluded=True)
excluded = [c for c in generator.combos if c.excluded]
print(str(Output.create(generator, "exclude_inline")))
```

`Combination` supports dimension attributes, item access, `hash_row()`, and
`append(key, value)`. Its `excluded_by_rule` property identifies the matching
exclusion. Row dictionaries are shallow copies, without display annotations.

## Examples

The Python examples mirror the working Ruby examples and are also test fixtures:

```sh
uv run python doc/cart.py
uv run python doc/pricing.py
uv run python doc/bounding_box.py
uv run python doc/expect_only.py
```

The obsolete Ruby DSL/CLI is not ported. Use Python scripts or import the package.

## Tests

```sh
uv run python -m unittest discover -s tests -v
```

Tests cover the API, rule precedence, edge cases, repeatable rendering, and
17 output snapshots across the four examples. Snapshots come from the Ruby
implementation; Python-expression text uses `and` instead of `&&`. Ruby is not
needed to run the Python tests. To regenerate the snapshots with the Ruby gem's
`tablesmith` dependency installed:

```sh
ruby tests/export_ruby_fixtures.rb > tests/fixtures/ruby_outputs.json
```

The existing Ruby specs remain unchanged:

```sh
rspec -Ilib -rdelegate -rcasegen
```

## License

[MIT](LICENSE).
