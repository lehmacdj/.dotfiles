---
description: "Find and address the `COMMENT:` annotations I leave inline in files as review notes (directives, questions, or both), then remove the ones that were resolved. Use when I ask to address, resolve, or handle comments / COMMENT annotations, optionally in specific files."
user-invocable: true
---

I leave review notes inline as `COMMENT: <text>` annotations — usually inside
the file's own comment syntax, sometimes as a bare line in prose or markdown.
Find and address all of them.

**Input**: Optional file path(s) or glob. Searches all tracked files
(`jj file list`) if none specified.

**Process**:
1. Search the target files for the literal, case-sensitive marker `COMMENT:`.
   - A note may continue over the following comment lines; read to its end.
   - Skip matches that are not annotations: the word in ordinary prose, or
     code and docs that are *about* the marker (like this skill).
2. Each annotation refers to the content next to it (normally the line or
   block just below, or the line it trails). Read enough context to be sure
   what it is about, then decide what it asks for:
   - **Directive**: apply the requested change to the surrounding content
   - **Question**: answer in your response; update the content if the answer
     affects it
   - **Both**: some comments raise a question while also implying a change —
     answer the question and apply the change
3. Propagate changes to downstream files if needed (other files that repeat
   or depend on what you changed).
4. Remove each annotation only if it was fully addressed, taking its comment
   delimiters and any line it leaves empty with it. Leave an annotation in
   place when it is ambiguous, needs a decision that is mine to make, or you
   could not do what it asks.
5. Summarize per annotation (`file:line`): what changed, the answers to any
   questions, and which annotations remain unresolved and why.
