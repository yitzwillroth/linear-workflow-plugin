---
name: release
description: "Move a planned issue from Scheduling to Queuing, releasing it for implementation. Usage: /release HUB-123. Dispatches via haiku subagent."
---

# Release

Move an approved issue from Scheduling to Queuing, signaling it's released for implementation.

## Attribution

Every Linear status update must include awareness of the attribution convention. If a comment is posted as part of this operation, include:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Parse Arguments

The first token should be an issue identifier (`HUB-123`). If not provided, infer from conversation context. If ambiguous, ask.

## Step 2: Validate and Move

Use a **haiku subagent** to:

1. Fetch the issue and verify it's in **Scheduling** status
   - If it's in Planning → warn: "HUB-123 is still in Planning. Did you want to plan it first with `/plan HUB-123`?"
   - If it's already in Queuing or later → inform: "HUB-123 is already in Queuing/Working."
2. Move the issue to **Queuing** status

## Step 3: Cascade Status to Sub-Issues

**Linear does not automatically cascade status changes from parent to child issues.** After moving the parent to Queuing, check for sub-issues (phase stories created by `/approve`). If any exist, move **all** of them to Queuing as well.

Use a **haiku subagent** to:

1. List sub-issues of the parent (check `children` or query by `parentId`)
2. Move all sub-issues to **Queuing** in parallel

```
# For each sub-issue:
save_issue(id: "<sub-issue-id>", state: "Queuing")
```

If there are no sub-issues, skip this step silently.

## Step 4: Confirm

**"HUB-123 released to Queuing and available for implementation. Use `/implement HUB-123` to start building."**

If sub-issues were cascaded: **"HUB-123 and N stories released to Queuing. Use `/implement HUB-123` to start building."**
