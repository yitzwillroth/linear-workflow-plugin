---
name: implement
description: Start implementation of a planned issue. Creates stories (epics) or checklists (tasks), builds a TodoWrite list, and begins coding. Invoke with /implement TEC-123 or just /implement if the target is clear from context.
---

# Implement

Begin implementation of a planned and approved issue. This skill reads the plan, creates the execution scaffolding (stories/checklists + TodoWrite), and starts coding.

## Attribution

Every Linear comment and issue body update made during implementation must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`. Include this signature on all comments and description edits posted via haiku subagents.

## Step 1: Identify the Target Issue

### With an argument (`/implement TEC-123`):
Fetch the issue with `get_issue(id: "TEC-123")`.

### Without an argument (`/implement`):
Infer the target from conversation context — typically the issue just created or discussed via `/plan` and `/approve`. If the target is ambiguous, ask: "Which issue should I implement? I see we've been discussing [X] and [Y]."

### Validate readiness:
- The issue should be in **Scheduling** or **Queuing** status. If it's in Planning, ask: "This issue is still in Planning. Should I proceed, or did you want to plan it first with `/plan`?"
- The issue should have a plan document attached. If it doesn't, ask: "I don't see a plan document on this issue. Should I proceed without one, or create a plan first?"

## Step 2: Create Worktree and Branch

All implementation work happens in a git worktree to isolate changes from the main checkout (and from other agents working in parallel).

### Create the worktree:

Derive the issue short ID (e.g., `T-38` from `TEC-38`) and compose a branch name:

```bash
# From the project root:
git worktree add worktrees/<issue-short-id> -b <type>/<issue-short-id>-<slug> develop
```

Example:
```bash
git worktree add worktrees/T-38 -b chore/T-38-mechanical-enforcement develop
```

**All subsequent work in this session happens inside `worktrees/<issue-short-id>/`.** Change your working directory there immediately.

### Install dependencies:

```bash
cd worktrees/<issue-short-id>
composer install
```

### Link Herd sites for manual testing:

Link app directories that may need browser testing. Bench (the primary dev surface) gets a short subdomain under `hubble.test`:

```bash
cd worktrees/<issue-short-id>/apps/bench/public && herd link <issue-short-id>.hubble
```

This serves bench at `<issue-short-id>.hubble.test` (e.g., `T-45.hubble.test`).

If observatory is also needed:
```bash
cd worktrees/<issue-short-id>/apps/observatory/public && herd link <issue-short-id>.observatory.hubble
```

Only link apps that are relevant to the work — if you're only touching packages, `bench` is sufficient.

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

## Step 4: Read the Plan

Read **ALL** documents attached to the issue — the implementation plan AND any referenced exploratory or background documents. Don't rely solely on the issue description; the real detail is in the plan documents.

Understand:
- The objective and approach
- The implementation steps (and phases, if any)
- The test strategy
- Any open questions (raise these with the user before proceeding)

If there's a referenced exploratory document (linked from the issue), read that too for broader context.

## Step 5: Build the Execution Scaffolding

Re-read the plan's Implementation Steps. Determine the issue type from its labels.

### For issues labeled **Task**:
Tasks get checklists directly in the **issue description body** (appended below the existing summary). No sub-issues.

1. Compose a checklist from the implementation steps. Each item should be concrete and independently verifiable.
2. Use a **haiku subagent** to update the issue description, appending the checklist below any existing content:

```markdown

## Implementation Checklist
- [ ] Step 1 description
- [ ] Step 2 description
- [ ] Step 3 description
...

---
🤖 Claude · Session {8-char-UUID}
```

### For issues labeled **Epic**:
Epics have phase stories (sub-issues) with checklists on each.

#### If phase stories already exist (created by `/approve`):
The stories are already created with full descriptions. Do NOT recreate them. Instead:

1. Read the first story's description to understand the phase scope.
2. Compose a checklist of concrete implementation steps and append it to the **story's description body**.
3. The first story should already be in Working (moved in Step 3).

#### If no phase stories exist yet:
Create a story for each phase/major deliverable in the plan:
```
save_issue(title: "<phase title>", team: "Technologentsia", parentId: "<parent-issue-id>", state: "Queuing")
```
Then move the first story to **Working**.

#### For the first story (either case):
Read the relevant code and compose a checklist of concrete implementation steps. Write the checklist into the **story's description body** (append below existing content if `/approve` already populated a description):

```markdown

## Implementation Checklist
- [ ] Step 1 description
- [ ] Step 2 description
- [ ] Step 3 description

---
🤖 Claude · Session {8-char-UUID}
```

Use a **haiku subagent** for creating stories and writing descriptions.

Don't create checklists for future stories yet — create them when you pick each one up. This keeps them grounded in code you've actually read.

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
gh pr create --base develop --title "[TEC-NNN] <epic title>" --body "$(cat <<'EOF'
## Summary
<brief description of what this epic delivers>

## Stories
- [TEC-aaa] Story 1 description
- [TEC-bbb] Story 2 description
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
- Each commit on the branch should use the **sub-issue identifier** as its prefix (e.g., `[T-40]`, not `[T-38]`).
- The squash merge happens later via `/accept` — the PR exists for review, not for merge mechanics.

### 7e. Confirm to user:
**"Implementation is complete and moved to Reviewing. PR opened: [link]. Summary posted on the Linear issue. Please review when ready — use `/accept TEC-xxx` to squash merge and advance to Running, or `/remediate TEC-xxx` if there are issues to address."**
