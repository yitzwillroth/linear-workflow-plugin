---
name: release
description: "Move a planned issue from Scheduling to Queueing, releasing it for implementation. Usage: /release TEC-123. Dispatches via haiku subagent."
---

# Release

Move an approved issue from Scheduling to Queueing, signaling it's released for implementation.

## Attribution

Every Linear status update must include awareness of the attribution convention. If a comment is posted as part of this operation, include:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Parse Arguments

The first token should be an issue identifier (`TEC-123`). If not provided, infer from conversation context. If ambiguous, ask.

## Step 2: Validate and Move

Use a **haiku subagent** to:

1. Fetch the issue and verify it's in **Scheduling** status
   - If it's in Planning → warn: "TEC-123 is still in Planning. Did you want to plan it first with `/plan TEC-123`?"
   - If it's already in Queueing or later → inform: "TEC-123 is already in Queueing/Working."
2. Move the issue to **Queueing** status

## Step 3: Confirm

**"TEC-123 released to Queueing and available for implementation. Use `/implement TEC-123` to start building."**
