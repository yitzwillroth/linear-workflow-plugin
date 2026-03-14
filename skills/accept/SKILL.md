---
name: accept
description: "Accept a completed implementation: squash merge to develop, advance all Linear cards to Running, clean up. Usage: /accept TEC-123"
---

# Accept

The user has reviewed the implementation and accepted it. Squash merge the epic branch into develop, advance all associated Linear issues to Running, tear down the worktree, and clean up.

## Attribution

Every Linear comment must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Identify the Target Issue

### With an argument (`/accept TEC-123`):
Fetch the issue with `get_issue(id: "TEC-123")`.

### Without an argument (`/accept`):
Infer from conversation context — typically the issue just implemented. Check the current git branch name for a clue (e.g., `chore/T-38-mechanical-enforcement` → T-38). If ambiguous, ask.

### Validate readiness:
- The issue should be in **Reviewing** status. If it's in Working, warn: "TEC-123 is still in Working. Are you sure it's ready to accept?"
- If the issue has stories (sub-issues), ALL stories should be in Reviewing or Running. If any are in Working or earlier, warn and list the incomplete stories.

## Step 2: Identify the Branch and PR

### Determine the epic branch:
1. Check if you're currently on the epic branch (not `develop` or `main`)
2. If on `develop` or `main`, look for local branches matching the issue, or check the issue's `gitBranchName` field
3. The branch should have commits ahead of `develop`

### Check for a GitHub PR:
Run `gh pr list --head <branch-name>` to see if a PR exists for this branch. Note the PR number — you'll close it after the local merge (Step 3).

## Step 3: Squash Merge (always local)

**All merges are performed locally**, never via the GitHub PR merge button. This is required because implementation happens in git worktrees — the merge must be done from the main checkout to properly clean up the worktree and branch.

If you're currently inside a worktree (`worktrees/<issue-short-id>/`), change to the **main checkout** first.

### Ensure you're on develop in the main checkout:
```bash
cd <project-root>  # NOT the worktree
git checkout develop
git pull origin develop
```

### Squash merge:
```bash
git merge --squash <epic-branch>
git commit -m "<composed message>"  # See Step 4 for format
```

If a PR exists, close it after the local merge:
```bash
gh pr close <pr-number> --comment "Squash merged locally to develop."
```

## Step 4: Compose the Squash Merge Commit Message

Read the commit log on the epic branch (`git log develop..<branch> --oneline`) and the issue's plan document to compose a structured commit message.

### Format:

```
[TEC-NNN] type(scope): brief summary

One-paragraph description of what was accomplished and why.

## Stories completed

- [TEC-aaa] Brief description of story 1
- [TEC-bbb] Brief description of story 2
- [TEC-ccc] Brief description of story 3

## Notes

- Key decisions made during implementation and why
- Challenges encountered and how they were resolved
- Deviations from the plan and justification
- Insights that would help future work on this codebase

Plan: <linear-document-url>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Rules for the commit message:
- The `[TEC-NNN]` prefix is the **parent epic** issue identifier
- The `type` follows conventional commits: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`
- Each story in "Stories completed" uses the **sub-issue** identifier
- The plan URL comes from the issue's attached document
- Pass the message via HEREDOC to preserve formatting

## Step 5: Advance Linear Issues to Running

Use a **haiku subagent** to:

1. Move the parent issue to **Running**
2. Move ALL stories to **Running** (Linear does not cascade status changes)
3. Post a brief merge comment on the parent issue:

```markdown
Accepted and merged to develop.

Commit: `<short-sha>` on `develop`
PR: <full-pr-url>

---
🤖 Claude · Session {8-char-UUID}
```

### Cascade rules:
- **Every story moves to Running.** Do not skip any, regardless of current status.
- **If the issue has a parent** (is itself a story of a larger epic), check whether ALL siblings are now Running. If yes, move the parent to Running too. If no, report which siblings remain.

## Step 6: Clean Up Worktree and Herd Links

### Unlink Herd sites:
Remove any Herd links created for this worktree:

```bash
herd unlink bench-<issue-short-id>
herd unlink observatory-<issue-short-id>
```

Ignore errors if a link doesn't exist (not all issues link both apps).

### Remove the worktree and branch:

```bash
git worktree remove worktrees/<issue-short-id>
git branch -D <epic-branch>
```

The worktree must be removed before the branch can be deleted. Use `-D` (force) because squash merges don't register as merged in git's DAG.

## Step 7: Confirm

**"TEC-123 accepted: squash merged to develop and moved to Running. Branch `chore/T-38-...` deleted."**

If stories were cascaded: **"TEC-123 and N stories moved to Running."**

If a parent was also completed: **"All stories of TEC-100 are now complete — TEC-100 also moved to Running."**

If siblings remain: **"Parent TEC-100 still has open stories: TEC-124 (Reviewing), TEC-125 (Working)."**

If local merge (no PR): append **"Push develop when ready: `git push origin develop`"**

## Important Rules

1. **Always squash merge locally.** Never fast-forward, create merge commits, or merge via GitHub's PR button. Local merge is required to properly clean up the worktree.
2. **Always clean up worktrees and Herd links.** After merging, remove the worktree, delete the branch, and unlink Herd sites.
3. **Always cascade status to stories.** Linear does not propagate status from parent to children.
4. **The commit message is a delivery record.** It should be comprehensive enough that someone reading `git log develop` can understand what shipped without opening Linear. The Notes section is especially important — it captures the *why* and the *how*, not just the *what*.
5. **Run `just ci` before merging** if you haven't already confirmed the branch is green. Never merge a red branch.
