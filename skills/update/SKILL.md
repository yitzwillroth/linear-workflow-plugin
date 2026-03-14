---
name: update
description: Use when work has been added or revised after the initial completion summary was posted — ensures Linear, the GitHub PR, and the commit message all tell the same story.
---

# Update

Synchronize all delivery artifacts so they tell a consistent, accurate story of what was actually built. Use this whenever the implementation grew beyond what the initial completion summary described — a late addition, a revised approach, a preventive measure added after the fact.

## Attribution

Every Linear comment and issue body update must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Identify What Changed

Review the conversation since the last summary was posted. Identify:
- **New work** — features, tests, or fixes added after the summary
- **Revised work** — things that changed approach mid-implementation
- **Corrections** — errors in the original summary

If the user provided a description of the change (e.g., "we added smoke tests"), use that as the starting point.

## Step 2: Compose the Unified Story

Before updating anything, draft the delta — the addition or correction that all three artifacts need to reflect. This is the single source of truth you'll apply consistently across Linear, the PR, and the commit.

The delta should be concrete: what was added, why it matters, and how it relates to the original work.

## Step 3: Update Linear

Use a **haiku subagent** for all Linear writes.

### Checklist (if applicable):
If new steps were completed, check them off in the checklist by editing the description or checklist comment in-place.

### Summary comment:
1. Run `list_comments` to see the comments, noting that Linear returns newest-first — read chronologically (oldest→newest).
2. Find the most recent summary comment from this session (look for the attribution signature matching the current session UUID).
3. **If that summary comment IS the most recent comment**: edit it in-place, appending or amending to reflect the new work.
4. **If that summary comment is NOT the most recent comment** (other comments followed it): post a new summary comment with the delta.

Never edit summary comments from a previous session or remediation cycle — they are historical artifacts.

### Format for a new summary comment:

```markdown
## Update — [date]

<description of what was added or changed and why>

---
🤖 Claude · Session {8-char-UUID}
```

## Step 4: Update the GitHub PR

Always update the PR description to reflect current state, then post a comment notifying reviewers of the change.

### 1. Update the description:
```bash
gh pr edit <number> --body "$(cat <<'EOF'
<updated full PR body>
EOF
)"
```

Include the delta prominently — either in a new "## Update" section appended to the existing body, or integrated into the existing sections if the change is small enough.

### 2. Post a notification comment:
```bash
gh pr comment <number> --body "$(cat <<'EOF'
**Description updated** — <concise description of what changed and why>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

This ensures reviewers who already read the description are informed of the change.

## Step 5: Update the Commit Message

### If the branch has not been pushed (or force-push is safe):
Amend the most recent commit to include the delta:

```bash
git commit --amend -m "$(cat <<'EOF'
<original commit message, updated to include the new work>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

If the new work warrants its own commit (it's substantial and discrete), create a new commit instead of amending.

### If the branch has already been pushed and force-push is not safe:
Do not amend. Instead, note in your confirmation to the user that the commit message reflects the state at push time and the PR/Linear artifacts now carry the complete story.

## Step 6: Confirm to User

Summarize what was updated:

**"Updated: Linear comment [edited/posted], PR [description updated/comment posted], commit [amended/new commit/unchanged — already pushed]. All three now reflect [brief description of the delta]."**

## Rules

1. **One story.** The same facts appear in all three places. Don't soften or omit in one artifact what you state in another.
2. **Edit in-place when possible.** Prefer updating existing artifacts over creating new ones — a clean timeline is easier to follow than a sequence of addendum comments.
3. **Don't duplicate history.** If a previous summary comment accurately describes earlier work, leave it alone. Only update or create the artifact that covers the new delta.
4. **Commit hygiene.** Amending rewrites history. Only amend if the branch is local or if the user has explicitly authorized force-push for this branch.
