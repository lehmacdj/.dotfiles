---
description: "Find and address COMMENT/QUESTION annotations in files"
user-invocable: true
---

Find and address all `COMMENT:` and `QUESTION:` annotations.

**Input**: Optional file path(s) or glob. Searches all tracked
files if none specified.

**Process**:
1. Find all COMMENT/QUESTION lines in target files
2. **COMMENT**: Apply the direction, update surrounding content
3. **QUESTION**: Answer in your response, update content if the
   answer affects it
4. Propagate changes to downstream files if needed
5. Remove each annotation only if successfully addressed; leave
   unresolved ones in place
6. Summarize what changed and flag any unresolved annotations
