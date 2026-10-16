"""Generate combinations of variables restricted by rules."""

from .core import EXPECT, Combination, ExcludeRule, ExpectRule, Generator
from .output import (
    Exclude,
    ExcludeAsTable,
    ExcludeAsText,
    ExcludeInline,
    ExcludeInlineFootnotes,
    Output,
)

__all__ = [
    "EXPECT",
    "Combination",
    "ExcludeRule",
    "ExpectRule",
    "Generator",
    "Output",
    "Exclude",
    "ExcludeAsTable",
    "ExcludeAsText",
    "ExcludeInline",
    "ExcludeInlineFootnotes",
    "combinations",
    "generate",
]


def combinations(sets, rules=None):
    """Return non-excluded combinations as dictionaries."""
    return Generator(sets, rules).rows()


def generate(sets, rules=None, output_type="exclude"):
    """Render combinations using one of the five exclusion output formats."""
    return str(Output.create(Generator(sets, rules), output_type))
