---
name: complete
description: "Mark a Linear issue as Running after user review. Usage: /complete TEC-123. Dispatches via haiku subagent."
---

# Complete

The user has reviewed the implementation and is satisfied. Mark the issue as Running.

## Attribution

Every Linear comment and status update must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Parse Arguments

The first token should be an issue identifier (`TEC-123`). If not provided, infer from conversation context. If ambiguous, ask.

## Step 2: Mark Complete

Use a **haiku subagent** to:

1. Move the issue to **Running** status.
2. Check whether this issue has a parent (is a sub-issue):
   - If it has a parent → check: are **ALL** sibling sub-issues also in Running?
     - If yes → move the parent issue to **Running** as well
     - If no → leave the parent as-is and inform the user which sub-issues remain
3. Check whether this issue has children (is a parent with sub-issues):
   - If it has sub-issues that are **NOT all Running** → do NOT move the parent to Running. Instead, inform the user which sub-issues still need to be completed. Each sub-issue should be completed individually with its own `/complete` invocation.
   - If ALL sub-issues are already Running → move the parent to Running.

### Important:
- **Move sub-issues individually as they are completed.** Do not batch-complete all sub-issues when completing a parent. Each sub-issue represents a distinct phase of work and should be reviewed and completed on its own.
- **The parent moves to Running only when all sub-issues are Running.** This happens automatically when the last sub-issue is completed.
- **Linear does not cascade status changes.** The parent and each sub-issue must be moved explicitly.

## Step 3: Confirm

### For a standalone issue (no parent, no children):
**"TEC-123 marked as Running."**

### For a sub-issue where the parent also completes:
**"TEC-123 marked as Running. All sub-issues of TEC-100 are now complete — TEC-100 also marked as Running."**

### For a sub-issue where siblings remain:
**"TEC-123 marked as Running. Parent TEC-100 still has open sub-issues: TEC-124 (Reviewing), TEC-125 (Working)."**

### For a parent issue invoked directly:
If all sub-issues are Running: **"TEC-100 marked as Running (all sub-issues already complete)."**
If sub-issues remain: **"TEC-100 has sub-issues that are not yet Running: TEC-124 (Reviewing), TEC-125 (Working). Complete each sub-issue individually with `/complete TEC-xxx` — the parent will move to Running when all sub-issues are done."**
