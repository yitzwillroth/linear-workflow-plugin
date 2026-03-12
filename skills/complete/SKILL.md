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

1. Move the issue to **Running** status
2. If the issue is a subtask, check: are ALL sibling subtasks also Running?
   - If yes → move the parent issue to **Running** as well
   - If no → leave the parent as-is and inform the user which subtasks remain

## Step 3: Confirm

**"TEC-123 marked as Running."**

If the parent was also completed: **"TEC-123 and parent TEC-100 both marked as Running — all subtasks are complete."**

If siblings remain: **"TEC-123 marked as Running. Parent TEC-100 still has open subtasks: TEC-124, TEC-125."**
