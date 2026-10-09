---
name: language-design
description: "Design or revise the syntax and semantics of a programming language, query language, command language, or DSL. Use when choosing behavior, reconciling language laws, or prototyping a semantic redesign. Do not use for routine parser or implementation fixes with already-settled behavior."
---

# Language design

Help the user reach a coherent behavioral model and validate it before costly
implementation. Scale the work to the uncertainty: a narrow change may need
only a distinguishing example, while a substantial redesign may need an
executable model and a maintained specification. Do not turn this guidance
into a mandatory checklist or an approval gate for ordinary coding.

## Establish the intended behavior

Read the relevant specification, implementation, tests, and existing decisions.
Separate user requirements from inherited behavior, implementation accidents,
and untested assumptions. Existing behavior is evidence of compatibility costs,
not proof that it is desirable or correct.

Identify the user-facing purpose of the construct before comparing mechanisms.
Record what a rule observes: returned values, multiplicity, ordering, bindings,
errors, or mutations. Equality of final results need not imply interchangeability
inside a larger expression. State the scope and preconditions of each law;
distinguish whole-expression equality from equality under substitution.

Resolve facts from the code or experiments. Ask about consequential behavioral
choices that existing decisions do not settle. Approval of one example does
not establish a universal law: expose materially different consequences before
generalizing. Continue independent work while a choice is unresolved.

## Compare models, not just patches

Default to simplicity of the finished language and codebase. Compare concepts,
mechanisms, state, exceptions, and maintenance costs separately from migration
effort and runtime cost. Reusing existing machinery can save implementation
effort while preserving unnecessary lasting complexity.

When laws conflict or fixes keep trading one invariant violation for another,
show the smallest conflict and reconsider the model. Include options such as
restricting the troublesome input class, relaxing a law, or removing a mechanism
alongside local repairs. Explain the useful behavior each option gives up; do
not assume the user prefers rejection or reduced expressiveness.

Prefer rules stated in terms of meaning over lists of syntactic exceptions.
Check whether an equivalent spelling or a nested construct bypasses a proposed
restriction. Where an existing representation or analysis expresses the rule,
consider reusing it before inventing another heuristic; verify its scope and
cost rather than assuming reuse is simpler.

## Make decisions understandable

When a consequential choice remains, present one substantive decision at a
time, keeping independent questions separate. Give the general rule, a minimal
distinguishing example, the outcomes under each option, and a recommendation
with its cost. Use a concrete input or graph when the result depends on data.
Include an ordinary case as a baseline.

Show intermediate expansions when copying, binding, grouping, or scope matters;
make shared identities and fresh copies visible. Define shorthand and custom
terms where used instead of relying on remembered labels such as "law L" or
"option 2". Label existing behavior, proposed behavior, and measured results.
If an explanation does not land, change representation: for example, move from
algebra to a small graph or an execution trace rather than repeating the jargon.

## Prototype the uncertain semantics

For a substantial change, implement the smallest useful model of the proposed
rules before optimizing or integrating it. Keep experiments out of commit
history. State unresolved assumptions and use the prototype to compare options;
do not silently promote an assumption into production behavior.

Start with examples that distinguish the competing models. Exercise relevant
feature interactions, especially nested and repeated composition, boundaries,
and transformations claimed to preserve meaning. A test generator producing
many cases cannot compensate for omitting a structural interaction.

Where practical, use a small independent evaluator or explicit expansion as an
oracle. It should not merely reuse the compiler pass being tested. Compare
against the old implementation to measure compatibility changes, not to define
correctness. Group differences by behavior and reduce failures to explanatory
counterexamples. For a claimed law, state what the checks establish and what
remains untested; passing examples are not a proof.

Measure costs that could change the design choice, using representative inputs
and builds. Bound expensive experiments per case, retain partial results, and
treat timeouts as results. Avoid polishing or optimizing a mechanism whose
semantics are still being reconsidered.

## Carry decisions into implementation

For a substantial redesign, maintain one concise behavioral specification in
the project's established documentation. Keep syntax, rules, scoped laws,
examples, and open decisions distinct from lowering and internal representation.
Mark superseded decisions. Reuse existing documents rather than creating a
parallel catalogue or transcript of the discussion.

Give implementers the accepted rules, distinguishing examples, compatibility
changes, and unresolved choices. Ordinary implementation details remain theirs
to decide; new observable semantic choices should return with a concrete example.
Preserve the useful prototype cases as regression tests in the implementation.

Use independent review when the semantic change warrants it. Review the model
and its claims as well as the code. When a counterexample appears, determine
whether it exposes a coding defect, an incomplete rule, or conflicting goals
before commissioning another patch. Do not remove valuable review merely to
reduce the number of rounds.
