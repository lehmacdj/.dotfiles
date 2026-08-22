---
description: "Find and address COMMENT annotations in files"
user-invocable: true
---

Find and address all `COMMENT:` annotations.

**Input**: Optional file path(s) or glob. Searches all tracked
files if none specified.

**Process**:
1. Find all COMMENT lines in target files
2. Each COMMENT may be a directive, a question, or a mix of both.
   Use context and judgment to determine the best response:
   - **Directive**: Apply the requested change to surrounding content
   - **Question**: Answer in your response, update content if the
     answer affects it
   - **Both**: Some comments raise a question while also implying a
     change — answer the question and apply the change
3. Propagate changes to downstream files if needed
4. Remove each annotation only if successfully addressed; leave
   unresolved ones in place
5. Summarize what changed and flag any unresolved annotations
