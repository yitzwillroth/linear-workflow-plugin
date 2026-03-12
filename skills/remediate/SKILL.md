---
name: remediate
description: "Dual-mode: (1) /remediate TEC-123 <feedback> posts organized feedback and moves to Queueing, or (2) /remediate TEC-123 (no feedback) reads existing remediation comment, moves to Working, and begins fixing."
---

# Remediate

Dual-mode skill for managing remediation feedback on Linear issues.

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
```

Omit sections that don't apply.

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

Fetch the issue and its comments. Find the most recent comment containing `## Remediation Feedback`. This is the feedback to act on.

If no remediation comment is found, tell the user: **"No remediation feedback found on TEC-123. Use `/remediate TEC-123 <your feedback>` to post feedback first."**

### Step 3F: Summarize to User

Present the remediation feedback concisely so the user can confirm scope before work begins.

### Step 4F: Move to Working & Post Checklist

Use a **haiku subagent** to:

1. Move the issue to **Working** status
2. If the issue has a parent, move the parent to **Working** if it's in Planning or Queueing
3. Remove the **Remediation** label
4. Post a **Remediation Checklist** comment derived from the feedback:

```markdown
## Remediation Checklist
- [ ] Action item 1
- [ ] Action item 2
- [ ] Action item 3
```

### Step 5F: Build TodoWrite

Mirror the checklist items into a TodoWrite list for session tracking. Add a final item: "Verify remediation fixes the reported issue". Mark the first task as `in_progress`.

### Step 6F: Fix

Begin fixing, following these discipline patterns (same as /implement):

- **Progress tracking**: Mark TodoWrite tasks complete as you finish each. Periodically dispatch a haiku subagent to check off checklist items in Linear.
- **Scope lock**: Only fix what the remediation feedback describes. If you discover additional issues, note them but don't fix them unless they're blocking the remediation.
- **Tool selection**: Serena LSP for structural nav, ColGrep for behavioral queries, ast-grep for patterns, Grep for text.

### Step 7F: Completion

When the fix is complete:

1. **Verify** — confirm the reported issue is resolved (run tests, check the specific failure scenario)
2. **Finalize Linear** — via haiku subagent: check off remaining checklist items, move issue to **Reviewing**, move parent to **Reviewing** if all subtasks are done
3. **Post summary** — as a comment on the issue and in the conversation:
   - What was fixed
   - Root cause
   - Files changed
4. **Confirm**: **"Remediation complete for TEC-123, moved to Reviewing. Use `/complete TEC-123` to mark as Running, or `/remediate TEC-123` again if issues remain."**
