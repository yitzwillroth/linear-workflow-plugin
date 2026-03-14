---
name: handoff
description: End-of-session review. Squeezes all juice from the session — updates Linear, saves durable learnings to memory, updates project docs, and writes a handoff file so the next session can pick up where this one left off. Use when wrapping up a session.
---

# Handoff

The session is winding down. Review what happened, persist everything valuable, and write the baton file for the next session.

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

Use a **haiku subagent** for all Linear writes. Skip this step if no Linear issue was in flight.

### If implementation was in flight:
- Update checklist progress by **editing the checklist comment or description in-place** (check off completed items) — do NOT post a new comment showing completion
- **Comment ordering**: When looking for the checklist comment to update, read comments chronologically (oldest→newest). An issue may have comments from multiple sessions or remediation cycles — Linear's `list_comments` returns newest-first. Always target the checklist from the **current** session/cycle. Never edit comments from a previous cycle — they are historical artifacts.
- If a story is partially complete, add a comment noting where work stopped and what remains
- Move completed stories to **Reviewing** if their checklists are fully done
- Do NOT move issues to Reviewing unless the work is actually complete

### For all sessions with a Linear issue:
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
If insights or decisions apply to other issues (parent, sibling stories, related issues), post brief comments on those too (with attribution).

## Step 3: Save Durable Learnings to Memory

If the session revealed anything that would be valuable **across many future sessions**:
- **Codebase insights** that aren't obvious from the code → `project_` prefixed memory file
- **User preferences** or workflow corrections → `feedback_` prefixed memory file
- **External references** discovered → `reference_` prefixed memory file

Save to `~/.claude/projects/{project-path}/memory/` and update `MEMORY.md` index.

Only save what's genuinely durable. Ephemeral task state belongs in the handoff file (Step 5), not memory.

## Step 4: Update Project Documentation

If the session established conventions, changed architectural decisions, or introduced patterns that belong in project docs:
- Update `CLAUDE.md` if it affects how agents should work in this project
- Update skill files if workflow conventions changed
- Commit and push documentation changes

Skip this step if nothing warrants a doc update.

## Step 5: Write the Handoff File

Write a context snapshot to `~/.claude/projects/{project-path}/handoff.md`. This file is the **baton** — it exists solely so the next session can re-establish context via `/pickup`.

The handoff file is **overwritten each time**, not appended. It's ephemeral state, not a log.

### Format:

```markdown
# Handoff — [date]

## Session Context
- **Issue**: [HUB-xxx or "no issue in flight"]
- **Branch**: [branch name and worktree path, or "main checkout"]
- **Git state**: [clean/dirty, commits ahead of develop, PR status]

## What Happened
[2-4 sentence narrative of what this session accomplished]

## Where We Stopped
[Precise description of the stopping point — what was the last thing done, what's the immediate next step]

## In-Flight State
- [Checklist items completed vs remaining]
- [Files modified but not committed]
- [Tests passing/failing]
- [Any temporary state that needs attention]

## Decisions Made
- [Key decisions with brief rationale — things the next session shouldn't re-litigate]

## Open Questions
- [Unresolved items that need the user's input or further investigation]

## Recommended Pickup
[Specific command or action for the next session, e.g., `/implement HUB-45` or `/pickup` then continue with step 4 of the plan]
```

Omit sections that don't apply (e.g., no "Open Questions" if there aren't any). Keep it concise — this is a context snapshot, not a narrative.

## Step 6: Confirm to User

Summarize what was captured and where:
- Which Linear issues were updated (if any)
- What was saved to memory (if anything)
- What docs were updated (if any)
- That the handoff file was written

**"Session handed off. Handoff file written — next session can run `/pickup` to resume. [Additional details about Linear/memory/docs updates]."**
