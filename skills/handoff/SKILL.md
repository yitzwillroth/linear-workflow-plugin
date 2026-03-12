---
name: handoff
description: End-of-session review. Enriches Linear artifacts with insights, updates checklist progress, and saves durable learnings to memory. Use when wrapping up a session before context gets stale.
---

# Handoff

The session is winding down. Review what happened and make sure everything valuable is captured in the right places before the conversation ends.

## Attribution

Every Linear comment posted during handoff must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Review the Session

Scan the conversation for:
- **Decisions made** — approach choices, design decisions, constraints established
- **Work completed** — code written, tests added, files changed
- **Work in progress** — tasks started but not finished
- **Insights discovered** — things learned about the codebase, patterns, gotchas
- **Open questions** — unresolved items that need attention in the next session

## Step 2: Update Linear Artifacts

Use a **haiku subagent** for all Linear writes.

### If implementation was in flight:
- Update checklist progress by **editing the checklist comment or description in-place** (check off completed items) — do NOT post a new comment showing completion
- If a subtask is partially complete, add a comment noting where work stopped and what remains
- Move completed subtasks to **Reviewing** if their checklists are fully done
- Do NOT move issues to Reviewing unless the work is actually complete

### For all sessions:
- Post a **session summary comment** on the primary issue being worked on. Format:

```markdown
## Session Summary — [date]

### Completed
- [bullet list of what was done]

### In Progress
- [what was started but not finished, and where it stands]

### Decisions
- [any decisions made during this session]

### Next Steps
- [what the next session should pick up]

---
🤖 Claude · Session {8-char-UUID}
```

### Enrich related issues:
If insights or decisions apply to other issues (parent, sibling subtasks, related issues), post brief comments on those too (with attribution).

## Step 3: Save Durable Learnings to Memory

If the session revealed anything that would be valuable in future conversations:
- **Codebase insights** that aren't obvious from the code → project memory
- **User preferences** or workflow corrections → feedback memory
- **External references** discovered → reference memory

Only save what's genuinely durable. Don't save ephemeral task state — that lives in Linear.

## Step 4: Confirm to User

Summarize what was captured and where:
- Which Linear issues were updated
- What was saved to memory (if anything)
- What the next session should start with

**"Session handoff complete. [Issue TEC-xxx] has been updated with progress and a session summary. Next session can pick up with `/implement TEC-xxx`."**
