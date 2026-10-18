---
name: search-corpora
description: "How to find a specific item in a large set of long, multi-topic documents — past Claude Code sessions in ~/.claude/projects/, notes in ~/wiki/, log files, chat exports. Use when asked to find a past session, conversation, or note, or whenever keyword search over such a corpus returns too many candidates."
user-invocable: true
---

When asked to find a specific item in a large set of long documents — past Claude Code sessions in `~/.claude/projects/`, notes in `~/wiki/`, log files, chat exports, etc. — ask for more details when materially different candidates remain and you cannot reasonably distinguish them from the available context. A large number of search matches alone is not a reason to ask.

## Things to avoid

- **Treating the document's opening as its topic.** Long sessions/notes accrete unrelated content; the relevant passage may be the 7th prompt, not the 1st. First-N-prompt extraction is brittle.
- **Filtering by file mtime as a proxy for when work happened.** A session reopened later for cleanup has a misleading mtime. Same for notes edited long after their original topic.
