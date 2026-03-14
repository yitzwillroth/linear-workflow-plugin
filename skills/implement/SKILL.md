---
name: implement
description: Start implementation of a planned issue. Reads self-contained story descriptions, builds a TodoWrite list from existing checklists, and begins coding. Invoke with /implement HUB-123 or just /implement if the target is clear from context.
---

# Implement

Begin implementation of an approved issue. This skill reads the issue's self-contained description (populated by `/approve`), builds execution scaffolding (TodoWrite from existing checklists), and starts coding.

## Attribution

Every Linear comment and issue body update made during implementation must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`. Include this signature on all comments and description edits posted via haiku subagents.

## Step 1: Identify the Target Issue

### With an argument (`/implement HUB-123`):
Fetch the issue with `get_issue(id: "HUB-123")`.

### Without an argument (`/implement`):
Infer the target from conversation context — typically the issue just created or discussed via `/plan` and `/approve`. If the target is ambiguous, ask: "Which issue should I implement? I see we've been discussing [X] and [Y]."

### Validate readiness:
- The issue should be in **Scheduling** or **Queuing** status. If it's in Planning, ask: "This issue is still in Planning. Should I proceed, or did you want to plan it first with `/plan`?"
- The issue description should contain implementation context (objective, approach, checklist). If the description is empty or minimal, check for an attached plan document. If neither exists, ask: "This issue has no implementation context. Should I proceed, or create a plan first?"

## Step 2: Create Worktree and Branch

All implementation work happens in a git worktree to isolate changes from the main checkout (and from other agents working in parallel).

### Create the worktree:

Derive the issue short ID (e.g., `HUB-38`) and compose a branch name:

```bash
# From the project root:
git worktree add worktrees/<issue-short-id> -b <type>/<issue-short-id>-<slug> develop
```

Example:
```bash
git worktree add worktrees/HUB-38 -b chore/HUB-38-mechanical-enforcement develop
```

**All subsequent work in this session happens inside `worktrees/<issue-short-id>/`.** Change your working directory there immediately.

### Install dependencies:

```bash
cd worktrees/<issue-short-id>
composer install
```

### Link Herd site for manual testing:

Link the relevant app directory for browser testing. The issue short ID becomes the `.test` subdomain:

```bash
cd worktrees/<issue-short-id>/apps/<app>/public && herd link <issue-short-id>
```

This serves the app at `<issue-short-id>.test` (e.g., `hub-38.test`). Use `bench` as the app unless the work is observatory-specific.

## Step 3: Move to Working

Move the target issue to **Working**:

```
save_issue(id: "<issue-id>", state: "Working")
```

### For Epics with existing phase stories:
If the target is an Epic and already has phase stories (created by `/approve`), move **only the first story** to Working. Leave the remaining stories at their current status — they will be moved to Working individually as you begin work on each one.

```
# Move epic to Working
save_issue(id: "<epic-id>", state: "Working")
# Move ONLY the first phase story to Working
save_issue(id: "<first-story-id>", state: "Working")
```

### Promote parent issue if needed:
If the issue is a story (has a parent epic), check the parent's status. If the parent is in **Planning** or **Queuing**, move it to **Working** as well.

Use a **haiku subagent** for these status updates.

## Step 4: Read the Implementation Context

**The issue description is the primary source of truth.** Stories created by `/approve` are self-contained — they include the objective, approach, checklist, and test strategy drawn from the original plan.

Read the issue description thoroughly. Understand:
- The objective and approach
- The checklist (implementation steps)
- The test strategy
- Any constraints or decisions noted

**For epic stories**: also read the parent epic's description for broader context on what the epic is setting out to achieve.

**If a plan document is attached** (on the epic, as historical reference): you may read it for additional context, but the story description is authoritative. If they conflict, follow the story description.

## Step 5: Build the Execution Scaffolding

Read the issue description and determine the issue structure from its labels and content.

### If a checklist already exists (created by `/approve`):

Stories created by `/approve` already have self-contained descriptions with granular checklists. **Do NOT recreate or duplicate checklists.** Instead:

1. Read the existing checklist to understand the scope of work.
2. If the checklist needs refinement after reading the actual code (e.g., a step needs splitting, or a missing step is discovered), update the existing checklist in-place via a **haiku subagent**.
3. Proceed to building the TodoWrite list from the existing checklist.

### If no checklist exists:

Compose a checklist from the issue description and your understanding of the code. Write it into the **issue description body** (append below existing content):

```markdown

## Checklist
- [ ] Step 1 description
- [ ] Step 2 description
- [ ] Step 3 description
...

---
🤖 Claude · Session {8-char-UUID}
```

Use a **haiku subagent** for writing descriptions.

### For epics with no stories yet:

If the epic has no sub-issues, create stories for each major deliverable:
```
save_issue(title: "<story title>", team: "HubbleOps", parentId: "<epic-id>", labels: ["Story", "<classification>"], state: "Queuing")
```
Populate each story with a self-contained description and checklist. Then move the first story to **Working**.

### Create the TodoWrite list:
Build a TodoWrite list from the checklist you just created. This is your session-scoped execution tracker. Include:
- Every step from the checklist, in execution order
- A final task: "Verify implementation against plan"

Mark the first task as `in_progress`.

## Step 6: Implement

Begin coding, following the TodoWrite list. As you work:

### Progress tracking:
- Mark TodoWrite tasks complete immediately as you finish each one (don't batch)
- **After every single completed item**, dispatch a **haiku subagent** to check off that item in the Linear checklist (edit the description or comment in-place). Do NOT batch these — every completion triggers an immediate Linear update.
- **Comment ordering**: When editing a checklist comment (not description), ensure you're editing the correct one. An issue may have comments from multiple sessions or remediation cycles. Linear's `list_comments` returns newest-first — read chronologically (oldest→newest) and target the checklist from the **current** session or cycle. Never edit comments from a previous cycle.
- If you discover the task list needs to change: **pause coding**, update both the TodoWrite list and the Linear checklist, then continue

### Story status management:
- **Starting a new story**: Move it to **Working** before beginning work on it. Only one story should be in Working at a time (the one you're actively coding).
- **Completing a story**: When its checklist is fully complete, move it to **Reviewing** immediately — don't wait for all stories to be done.
- **The epic stays in Working** until ALL stories reach Reviewing or Running.

### Scope discipline:
The plan is scope-locked. You may perform localized code hygiene (formatting, fixing an adjacent typo) but nothing beyond that. If you feel tempted to introduce refactoring that isn't in the plan:
1. Stop coding
2. Describe the refactoring, its justification, and its implications
3. Wait for user approval before continuing

### When uncertain:
If you encounter ambiguity or a decision the plan doesn't cover:
1. Stop coding
2. Describe the uncertainty concisely
3. Wait for clarification before continuing

### When stuck:
If you hit a blocker:
1. Use the `counselors` CLI to explore options that align with the plan
2. If counselors yields a path forward — take it, but note what happened
3. If no path aligns with the plan — stop coding, describe the difficulty, and wait for guidance

### When deviating:
If you discover the task list must change to successfully implement the plan:
1. Stop coding
2. Update your TodoWrite list and the Linear checklist
3. You may then continue without waiting for confirmation — the updated list is your authorization

### Tool selection:
Before each task, briefly consider which tools are highest leverage:
- Serena LSP for structural navigation and symbol-level edits
- ColGrep for behavioral/intent queries
- ast-grep for structural pattern matching
- Grep for exact text matches

## Step 7: Completion

When you believe implementation is complete:

### 7a. Plan-diff check:
Re-read the original plan document. Compare it against what was implemented. Look for:
- **Gaps** — planned steps that weren't executed
- **Deviations** — implementation that diverged from the plan
- **Scope creep** — work that wasn't in the plan

Remediate any issues before declaring completion.

### 7b. Finalize Linear artifacts:
Use a **haiku subagent** to:
- Check off any remaining checklist items (edit in-place)
- Move the issue (or current story) to **Reviewing**
- If all stories of an epic are complete, move the epic to **Reviewing**

### 7c. Post completion summary:
Compose a summary and present it in the conversation AND post it as a comment on the Linear issue (via haiku subagent). The summary should include:

- **What was done** — concrete list of changes, files touched
- **Assumptions made** — decisions you made without asking
- **Challenges and resolutions** — anything that didn't go smoothly, including any use of `counselors` CLI
- **Insights** — anything learned that would be valuable for future work on this codebase, especially guidance that would help other agents working on the project

Do NOT repost the full checklist in the completion summary — it's already tracked in the description/comment.

Include the attribution signature on the completion comment.

### 7d. Push branch and open PR:

After all stories are committed and CI is green, push the epic branch and open a PR to `develop`:

1. Push the branch:
```bash
git push -u origin <epic-branch>
```

2. Open the PR with `gh pr create`. The PR should:
   - Target `develop` (not `main`)
   - Use the epic issue title as the PR title, prefixed with the issue identifier
   - Include a structured body with the completion summary

```bash
gh pr create --base develop --title "[HUB-NNN] <epic title>" --body "$(cat <<'EOF'
## Summary
<brief description of what this epic delivers>

## Stories
- [HUB-aaa] Story 1 description
- [HUB-bbb] Story 2 description
- ...

## Notes
- Key decisions, challenges, deviations, and insights from implementation

Plan: <linear-document-url>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Important PR guidance:**
- **Do NOT squash before opening the PR.** Keep discrete story commits visible so the reviewer can see each step individually.
- Each commit on the branch should use the **sub-issue identifier** as its prefix (e.g., `[HUB-40]`, not `[HUB-38]`).
- The squash merge happens later via `/accept` — the PR exists for review, not for merge mechanics.

### 7e. Confirm to user:
**"Implementation is complete and moved to Reviewing. PR opened: [link]. Summary posted on the Linear issue. Please review when ready — use `/accept HUB-xxx` to squash merge and advance to Running, or `/remediate HUB-xxx` if there are issues to address."**
