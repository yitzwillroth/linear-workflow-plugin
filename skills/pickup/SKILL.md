---
name: pickup
description: Resume work from a previous session. Reads the handoff file to re-establish context, then continues where the last session left off. Usage: /pickup
---

# Pickup

A previous session wrote a handoff file before ending. Read it and re-establish context so we can continue seamlessly.

## Step 1: Read the Handoff File

Read `~/.claude/projects/{project-path}/handoff.md`.

If the file doesn't exist or is empty, tell the user:
**"No handoff file found. What would you like to work on? You can point me at a Linear issue with `/implement HUB-xxx` or describe what you'd like to do."**

## Step 2: Re-establish Context

Based on the handoff file:

### If a worktree was in use:
1. Verify the worktree still exists: `ls worktrees/<issue-short-id>/`
2. Change working directory to the worktree
3. Check git state: `git status`, `git log --oneline -5`
4. Verify the branch matches what the handoff file describes

### If a Linear issue was in flight:
1. Fetch the issue to see current status and any new comments since the handoff
2. Read the checklist to understand what's done and what remains
3. If stories exist, check their statuses

### If tests were relevant:
1. Run `just ci` (or the relevant test command) to verify the current state
2. Note any failures that may have been introduced since the handoff

## Step 3: Orient the User

Present a brief summary of where things stand:

**"Picking up from [date]. [1-2 sentence summary of what was happening]. [Current state — what's done, what's next]. Ready to continue with [specific next action]."**

If anything has changed since the handoff (new comments on the issue, branch state differs from what was recorded), flag it:

**"Note: [what changed] since the handoff was written."**

## Step 4: Continue

Proceed with the recommended action from the handoff file, or wait for the user to direct otherwise. If the handoff recommended `/implement HUB-xxx`, pick up implementation from where it stopped — don't restart the skill from scratch, just continue with the remaining work.

## Important Rules

1. **Don't re-litigate decisions.** The handoff file records decisions made in the previous session. Honor them unless the user explicitly wants to revisit.
2. **Verify before assuming.** The handoff file is a snapshot — things may have changed. Always check git state and Linear status before diving in.
3. **Be concise.** The user ran `/pickup` because they want to get back to work, not read a novel. Orient quickly, then act.
