# CaseGen Review

April 2026.

## Current State

~540 lines of library code, 10 specs, 5 doc examples. Ruby gem (3.0.1).
The v3 rewrite dropped the DSL for plain Ruby — the right call.

## Strengths to Preserve

- **Plain Ruby API.** Sets are hashes, rules are hashes with criteria strings
  or lambdas. No parsing infrastructure, no DSL to learn. The people using
  this tool are Ruby programmers.

- **The expect pattern.** Using `:expect` as a sentinel for computed columns
  turns CaseGen from a combination generator into a specification table
  builder. The pricing and bounding_box examples show this well — you end up
  with a truth table that doubles as a test oracle.

- **Tiny, comprehensible codebase.** Generator is 40 lines. The whole thing
  fits in your head. Don't bloat it.

- **Runnable doc examples as fixtures.** The doc/ files are the best
  documentation. They're real scenarios, they run, and they double as test
  data via the Fixtures class.

## Bugs and Rough Edges

### Proc inspect strings in output

When criteria is a Proc rather than a String, the exclude text output shows
`#<Proc:0x00000001... (lambda)>` as the criteria line. Only string criteria
render meaningfully. The tool should use the description/note/reason text
instead, or omit the criteria line for Procs.

### Class-level attr_accessor leak

`Combination#append` calls `self.class.attr_accessor key`, which mutates the
class, not the instance. If two separate CaseGen runs happen in the same
process with different dimension names, accessors from the first run leak
into the second. Fine for short-lived scripts, latent bug for library use in
a long-lived process. Fix: use `define_method` on the singleton class, or
store values in a hash instead of ivars.

### No validation

- Misspelled dimension name in a rule: silently doesn't match.
- Expect rule for a nonexistent combination: silently ignored.
- Missing expect rule for a combination: `:expect` symbol appears in output.
- No feedback that your specification is incomplete.

### Rule ordering is implicit

Exclude rules run before expect rules because Ruby hash iteration order puts
`:exclude` before `:expect`. Writing `{ expect: [...], exclude: [...] }`
would produce wrong results. This should be enforced, not assumed.

### String criteria ergonomics

`instance_eval` on string criteria works but gives poor error messages (typo
in a variable name = confusing `NoMethodError` with no line context). The
lambda form is better in every way — syntax highlighting, IDE support,
Ruby-level errors. Consider whether string criteria earns its keep, or
whether it should be soft-deprecated in favor of lambdas.

## Improvements for Agentic Use

### Structured data output

`CaseGen.generate` returns a string (ASCII table). Agents and test code want
an array of hashes. The Generator already has this internally
(`combos.map(&:hash_row)`), but there's no public API.

```ruby
# Proposed
CaseGen.combinations(sets, rules)
# => [{payment: 'Credit', amount: 100, ...}, ...]
```

This is the highest-leverage change. It unblocks everything below.

### Completeness checking for expects

When using the `:expect` pattern, the tool should report which combinations
have no expect rule defined. Right now it silently leaves `:expect` in the
output. Surface this as a warning or a queryable result:

```ruby
result = CaseGen.analyze(sets, rules)
result.missing_expects  # => [{subtotal: 25, discount: '0%', promo: 'none'}, ...]
```

### Test framework integration

The expect_only example (duration/unit/result) is a parameterized test
waiting to happen:

```ruby
CaseGen.combinations(sets, rules).each do |c|
  it "formats #{c[:duration]} #{c[:unit]} as #{c[:result]}" do
    expect(format_duration(c[:duration], c[:unit])).to eq(c[:result])
  end
end
```

No new code in CaseGen needed — just the structured output API above. But
a doc example showing this pattern would make the connection explicit.

### Diff-friendly output

When the spec changes, you want to see which cases were added or removed.
The ASCII table format isn't great for diffing. Consider a sorted,
deterministic output mode (CSV, or one-case-per-line) that plays well with
git diff.

### Rule inference (exploratory)

Flip the workflow: instead of "define rules, generate cases," start from
"here are the cases I know about, what rules would produce them?" An agent
can help derive exclude rules from known-invalid combinations, or propose
expect values for uncovered cases. This is more of a workflow pattern than a
code feature, but CaseGen could support it with an API that accepts a partial
specification and reports gaps.

## Field Notes: Agentic Use on a Real Problem (April 2026)

Used CaseGen with Claude on a CI workflow problem — build dependencies
between apps, deploy scenarios, branch types. Claude generated the CaseGen
script from scratch after we'd already found a bug in an unconsidered case.
The tool confirmed the bug and surfaced the gap in our thinking.

Observations from that session:

### The anticipation paradox

CaseGen is a weird tool for its author to have built. As a proponent of the
Agile manifesto, the belief is that anticipation and risk management only
get you so far because of our inability to predict the future — a resilient
approach (responding to what actually happens) is what most folks end up
having to do anyway, and the more we acknowledge and embrace that, the
better.

CaseGen is pro-anticipation. It says: "Here's a framework that can force
you to anticipate better, hopefully." It exists to force you to think
through edge cases in advance, to confront every combination rather than
handwave past the ones that seem obvious.

One of the bigger forcing functions — and an unintended one — is the act of
choosing dimensions. You have to decide what the axes are before you can
generate anything. That decision is itself an analysis: which variables
interact? Which ones are independent? Sometimes you discover partway
through that you need to slice differently — two or three smaller tables
focused on different intersections of dimensions rather than one massive
table. That decomposition keeps the exponential explosion in check, but
more importantly it reveals the structure of the problem. "These three
things interact, but that fourth thing is orthogonal" is a design insight,
not just a CaseGen convenience.

The twist: in practice, usually halfway through the exercise you can give
up on the rigor because you've already gotten the value out of it. The act
of enumerating dimensions and writing the first batch of rules surfaces the
interesting cases. By the time you're staring at the remaining rows, your
brain has already done the important work. The unfilled rows aren't failure
— they're evidence that the tool did its job.

Claude accelerated this massively. But part of how it accelerated it was by
jumping over a class of subcases: "those look symmetric and are probably
already handled, there's probably low value in going through all of those."
An agent doing the tedious part faster also means it reaches the "diminishing
returns" point faster — and makes the pragmatic call to stop there.

There's a trust problem here too. Claude made the right pragmatic call
skipping those rows — but it could just as easily have been confidently
wrong. Agents are smart enough to recognize symmetry and boring enough to
grind through tedious rows, which is exactly the combination CaseGen needs.
But they also hallucinate and miss things with total confidence. The tool
shouldn't just trust the agent's judgment about what's boring any more than
it should trust the human's. It should make the skipping *visible* so
either party can challenge it later.

This suggests CaseGen's design should acknowledge the pattern rather than
fight it. Today, an unfilled expect and a deliberately-skipped case look
identical (`:expect` left in output). Options:

- A `:skip` or `:na` sentinel alongside `:expect`, meaning "I considered
  this and it doesn't need a value."
- Completeness checking that only flags genuinely unaddressed rows.
- A way to annotate skipped rows with *why* they're boring ("symmetric
  with row N", "same logic as the astro case").

The tool should make it easy to be rigorous where it matters and honest
about where you stopped.

### All-pairs as a reduction strategy inside CaseGen

CaseGen does exhaustive enumeration. James Bach's AllPairs does pairwise
reduction — mathematically prune to a smaller set that still covers every
pair of values across any two dimensions. These are complementary:

- Generate all combinations (CaseGen's strength)
- Apply all-pairs reduction to drop rows that don't add pairwise coverage
- Force annotation of the survivors

This would help at scale (8+ dimensions). For 4-5 dimensions the full
enumeration is manageable (~50 rows after exclusions). But the CI workflow
case was already bumping up against "too many rows to think about."

The risk: all-pairs guarantees pairwise coverage but not three-way
interactions. The actual bug we found was a three-way interaction
(prev_outcome × commit_type × branch). All-pairs might or might not have
kept that combination. So the reduction should be optional and clearly
labeled — "these rows were dropped by pairwise reduction, not by domain
rules."

### CaseGen as a conversation artifact

The most valuable part of the session wasn't the generated table — it was
the act of defining dimensions and rules together. The CaseGen script became
a shared artifact encoding our understanding of the problem space. When we
found the bug, we could point at a specific row and say "this case." That's
the thinking framework in action.

## The Big Picture

CaseGen's real value is the thinking framework, not the code. Defining
dimensions, identifying invalid combinations with reasons, specifying
expected outputs — that's structured test design. The act of building a
CaseGen script is the valuable part; the generated table is the artifact.

In an agentic world, this structured thinking is more valuable, not less. It
gives the agent something concrete and verifiable to work from, rather than
vibes-based "write tests for this feature." The tool needs to evolve its
interfaces to be agent-friendly (structured data) alongside human-friendly
(ASCII tables), without losing its simplicity.
