---
name: remediate
description: "Dual-mode: (1) /remediate TEC-123 <feedback> posts organized feedback and moves to Queueing, or (2) /remediate TEC-123 (no feedback) reads existing remediation comment, moves to Working, and begins fixing."
---

# Remediate

Dual-mode skill for managing remediation feedback on Linear issues.

## Attribution

Every Linear comment and issue update made during remediation must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`. Include this signature on all comments posted via haiku subagents.

## Step 1: Parse Arguments & Detect Mode

The first token should be an issue identifier (`TEC-123`). If not provided, infer from conversation context. If ambiguous, ask.

Everything after the identifier is the user's feedback. **The presence or absence of feedback determines the mode:**

- **Feedback provided** → **Post mode** (post feedback, route to Queueing)
- **No feedback** → **Fix mode** (read existing feedback, begin fixing)

---

## Post Mode

### Step 2P: Organize the Feedback

Take the user's raw feedback and structure it into a clear, actionable comment. Don't change the meaning — just organize it.

Format:

```markdown
## Remediation Feedback

### Issues Found
- [each distinct issue as a bullet, with enough context to act on]

### Expected Behavior
- [what the user expects, if stated or implied]

### Additional Context
- [any other details from the feedback that don't fit above]

---
🤖 Claude · Session {8-char-UUID}
```

Omit sections that don't apply (except the attribution signature — always include it).

### Step 3P: Post and Route

Use a **haiku subagent** to do all three in one dispatch:

1. Post the organized comment on the issue
2. Add the **Remediation** label to the issue
3. Move the issue to **Queueing** status

### Step 4P: Confirm

Show the user the organized comment you posted, and confirm:

**"Feedback posted to TEC-123 and moved to Queueing with Remediation label. This will be prioritized in the next implementation session."**

---

## Fix Mode

### Step 2F: Fetch Issue & Read Remediation Feedback

Fetch the issue and its comments. **Read comments chronologically (oldest → newest)** to find the correct remediation feedback. An issue may have multiple remediation cycles — you need the **most recent** `## Remediation Feedback` comment, which will be the one posted *after* the last "Remediation Complete" or "Remediation Summary" comment.

**Important**: Linear's `list_comments` returns newest-first. Reverse the order mentally or explicitly to find the latest remediation cycle. Never edit comments from a previous remediation cycle — they are historical artifacts.

If no unresolved remediation comment is found, also check for raw error reports (stack traces, error dumps) posted after the last completion — these may be the user's new feedback even without the `## Remediation Feedback` header.

If nothing applicable is found, tell the user: **"No remediation feedback found on TEC-123. Use `/remediate TEC-123 <your feedback>` to post feedback first."**

### Step 3F: Summarize to User

Present the remediation feedback concisely so the user can confirm scope before work begins.

### Step 4F: Move to Working & Post Checklist

Use a **haiku subagent** to:

1. Move the issue to **Working** status
2. If the issue has a parent, move the parent to **Working** if it's in Planning or Queueing
3. Remove the **Remediation** label
4. Post a **new** Remediation Checklist comment derived from the feedback (never reuse a previous cycle's checklist comment):

```markdown
## Remediation Checklist
- [ ] Action item 1
- [ ] Action item 2
- [ ] Action item 3

---
🤖 Claude · Session {8-char-UUID}
```

### Step 5F: Build TodoWrite

Mirror the checklist items into a TodoWrite list for session tracking. Add a final item: "Verify remediation fixes the reported issue". Mark the first task as `in_progress`.

### Step 6F: Fix

Begin fixing, following these discipline patterns (same as /implement):

- **Progress tracking**: Mark TodoWrite tasks complete as you finish each. **After every single completed item**, dispatch a haiku subagent to check off that item in the Linear checklist comment — **edit the comment in-place**, don't post a new comment showing completion.
- **Scope lock**: Only fix what the remediation feedback describes. If you discover additional issues, note them but don't fix them unless they're blocking the remediation.
- **Tool selection**: Serena LSP for structural nav, ColGrep for behavioral queries, ast-grep for patterns, Grep for text.

### Step 7F: Completion

When the fix is complete:

1. **Verify** — confirm the reported issue is resolved (run tests, check the specific failure scenario)
2. **Finalize Linear** — via haiku subagent: edit the checklist comment in-place to check off remaining items, move issue to **Reviewing**, move parent to **Reviewing** if all subtasks are done
3. **Post summary** — as a comment on the issue (with attribution) and in the conversation:
   - What was fixed
   - Root cause
   - Files changed
   Do NOT repost the full checklist — it's already tracked in the comment.
4. **Confirm**: **"Remediation complete for TEC-123, moved to Reviewing. Use `/complete TEC-123` to mark as Running, or `/remediate TEC-123` again if issues remain."**
