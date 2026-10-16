from .core import rule_description


def _text(value):
    if value is None:
        return ""
    if isinstance(value, bool):
        return str(value).lower()
    return str(value)


def _table(rows):
    if not rows:
        return "+---------+\n| (empty) |\n+---------+\n"
    columns = list(dict.fromkeys(key for row in rows for key in row))
    values = [[_text(row.get(key)) for key in columns] for row in rows]
    widths = [
        max(len(str(key)), *(len(row[index]) for row in values))
        for index, key in enumerate(columns)
    ]
    border = "+" + "+".join("-" * (width + 2) for width in widths) + "+"

    def line(cells, header=False):
        padded = []
        for cell, width in zip(cells, widths):
            padding = width - len(cell)
            left = padding // 2 if header else 0
            padded.append(" " + " " * left + cell + " " * (padding - left) + " ")
        return "|" + "|".join(padded) + "|"

    lines = [border, line([str(key) for key in columns], header=True), border]
    lines.extend(line(row) for row in values)
    return "\n".join([*lines, border, ""])


class Output:
    partition_exclusions = True

    def __init__(self, generator):
        self.generator = generator

    @staticmethod
    def create(generator, output_type="exclude"):
        formats = {
            "exclude": Exclude,
            "exclude_as_table": ExcludeAsTable,
            "exclude_as_text": ExcludeAsText,
            "exclude_inline": ExcludeInline,
            "exclude_inline_footnotes": ExcludeInlineFootnotes,
        }
        try:
            output_class = formats[output_type]
        except KeyError:
            raise ValueError(f"Unknown output type: {output_type}") from None
        return output_class(generator)

    def __str__(self):
        included, excluded = [], []
        for combo in self.generator.combos:
            row = combo.hash_row()
            if combo.excluded:
                row["exclude"] = self.exclude_description(combo.excluded_by_rule)
            destination = (
                excluded if self.partition_exclusions and combo.excluded else included
            )
            destination.append(row)
        return _table(included) + self.exclude_output(excluded)

    def exclude_description(self, rule):
        return None

    def exclude_output(self, rows):
        return ""


class Exclude(Output):
    pass


class ExcludeAsTable(Output):
    def exclude_description(self, rule):
        return rule.description

    def exclude_output(self, rows):
        return "\n" + _table(rows)


class ExcludeAsText(Output):
    def exclude_output(self, rows):
        lines = ["", "exclude", "-------"]
        for rule in self.generator.rules.get("exclude", []):
            criteria = rule.get("criteria")
            if isinstance(criteria, str):
                lines.append(criteria)
            lines.extend(["  " + _text(rule_description(rule)), ""])
        return "\n".join(lines)


class ExcludeInline(ExcludeAsTable):
    partition_exclusions = False

    def exclude_output(self, rows):
        return ""


class ExcludeInlineFootnotes(ExcludeInline):
    def exclude_description(self, rule):
        return f"[{rule.rule_data['index']}]"

    def exclude_output(self, rows):
        lines = ["", "exclude", "-------"]
        lines.extend(
            f"[{rule['index']}] {_text(rule_description(rule))}"
            for rule in self.generator.rules.get("exclude", [])
        )
        return "\n".join(lines)
