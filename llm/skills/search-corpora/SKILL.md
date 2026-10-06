---
name: search-corpora
description: "How to find a specific item in a large set of long, multi-topic documents — past Claude Code sessions in ~/.claude/projects/, notes in ~/wiki/, log files, chat exports. Use when asked to find a past session, conversation, or note, or whenever keyword search over such a corpus returns too many candidates."
user-invocable: true
---

When asked to find a specific item in a large set of long documents — past
Claude Code sessions in `~/.claude/projects/`, notes in `~/wiki/`, log files,
chat exports, etc. — and keyword grep produces too many candidates, step back
and ask for more details or extra bounds rather than guessing.

Useful things to ask for:
- distinctive vocabulary the user would have used (jargon, specific
  identifiers, characteristic phrasings)
- approximate dates
- any other constraint that narrows the candidate set

The user knows how they phrased things; a few well-chosen terms from them
collapse the search fast.

## Things to avoid

- **Treating the document's opening as its topic.** Long sessions/notes accrete
  unrelated content; the relevant passage may be the 7th prompt, not the 1st.
  First-N-prompt extraction is brittle.
- **Filtering by file mtime as a proxy for when work happened.** A session
  reopened later for cleanup has a misleading mtime. Same for notes edited long
  after their original topic.
