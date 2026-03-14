---
name: accept
description: "Accept a completed implementation: squash merge to develop, advance all Linear cards to Running, clean up. Usage: /accept TEC-123"
---

# Accept

The user has reviewed the implementation and accepted it. Squash merge the epic branch into develop, advance all associated Linear issues to Running, and clean up.

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
- If the issue has sub-issues, ALL sub-issues should be in Reviewing or Running. If any are in Working or earlier, warn and list the incomplete sub-issues.

## Step 2: Identify the Branch and PR

### Determine the epic branch:
1. Check if you're currently on the epic branch (not `develop` or `main`)
2. If on `develop` or `main`, look for local branches matching the issue, or check the issue's `gitBranchName` field
3. The branch should have commits ahead of `develop`

### Check for a GitHub PR:
Run `gh pr list --head <branch-name>` to see if a PR exists for this branch.

- **PR exists** → use `gh pr merge` for the squash merge (Step 3a)
- **No PR exists** → perform a local squash merge (Step 3b)

## Step 3a: Squash Merge via PR

Compose the squash merge commit message (see Step 4 for format), then:

```bash
gh pr merge <pr-number> --squash --subject "<title>" --body "<body>"
```

After the merge completes:
1. `git checkout develop && git pull origin develop`
2. `git branch -D <epic-branch>` (force-delete — squash merges don't register as merged)

## Step 3b: Local Squash Merge (no PR)

If no PR exists:

```bash
git checkout develop
git merge --squash <epic-branch>
git commit -m "<composed message>"  # See Step 4 for format
git branch -D <epic-branch>
```

Inform the user: "No PR found — performed local squash merge. Push develop when ready: `git push origin develop`"

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
2. Move ALL sub-issues to **Running** (Linear does not cascade status changes)
3. Post a brief merge comment on the parent issue:

```markdown
Accepted and merged to develop.

Commit: `<short-sha>` on `develop`

---
🤖 Claude · Session {8-char-UUID}
```

### Cascade rules:
- **Every sub-issue moves to Running.** Do not skip any, regardless of current status.
- **If the issue has a parent** (is itself a sub-issue of a larger feature), check whether ALL siblings are now Running. If yes, move the parent to Running too. If no, report which siblings remain.

## Step 6: Confirm

**"TEC-123 accepted: squash merged to develop and moved to Running. Branch `chore/T-38-...` deleted."**

If sub-issues were cascaded: **"TEC-123 and N sub-issues moved to Running."**

If a parent was also completed: **"All sub-issues of TEC-100 are now complete — TEC-100 also moved to Running."**

If siblings remain: **"Parent TEC-100 still has open sub-issues: TEC-124 (Reviewing), TEC-125 (Working)."**

If local merge (no PR): append **"Push develop when ready: `git push origin develop`"**

## Important Rules

1. **Always squash merge.** Never fast-forward or create merge commits on develop.
2. **Always force-delete the branch** (`-D`). Squash merges don't register as merged in git's DAG, so `-d` will fail.
3. **Always cascade status to sub-issues.** Linear does not propagate status from parent to children.
4. **The commit message is a delivery record.** It should be comprehensive enough that someone reading `git log develop` can understand what shipped without opening Linear. The Notes section is especially important — it captures the *why* and the *how*, not just the *what*.
5. **Run `just ci` before merging** if you haven't already confirmed the branch is green. Never merge a red branch.
