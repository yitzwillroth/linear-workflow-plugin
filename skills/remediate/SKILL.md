---
name: remediate
description: "Send review feedback to a Linear issue. Organizes your brain dump into a structured comment, adds the Remediation label, and moves the issue back to Queueing. Usage: /remediate TEC-123 followed by your feedback."
---

# Remediate

The user has review feedback for an issue. Organize it, post it, and route the issue back for work.

## Step 1: Parse Arguments

The first token should be an issue identifier (`TEC-123`). Everything after it is the user's feedback — a brain dump that may be informal, unstructured, or stream-of-consciousness.

If no issue identifier is provided, check conversation context for the most recently discussed issue. If still ambiguous, ask.

## Step 2: Organize the Feedback

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

Omit sections that don't apply (e.g., if there's no "additional context," skip that section).

## Step 3: Post and Route

Use a **haiku subagent** to do all three in one dispatch:

1. Post the organized comment on the issue
2. Add the **Remediation** label to the issue
3. Move the issue to **Queueing** status

## Step 4: Confirm

Show the user the organized comment you posted (so they can verify it captures their intent), and confirm:

**"Feedback posted to TEC-123 and moved to Queueing with Remediation label. This will be prioritized in the next implementation session."**
