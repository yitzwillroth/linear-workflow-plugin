---
name: approve
description: Approve a plan and finalize Linear artifacts. Unlocks editing tools, creates parent issue if needed, attaches plan document, and moves to Scheduling status. Does NOT start implementation — use /implement for that.
---

# Approve Plan

The user has reviewed and approved the plan. Finalize the artifacts and unlock editing tools — but do NOT begin implementation. The user will invoke `/implement` when ready to start building.

## Attribution

Every Linear comment and issue update must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Remove Session from Planning File

Run this command to deactivate planning mode:

```bash
~/.claude/hooks/planning-mode-toggle.sh deactivate
```

After unlocking, confirm: **"Planning mode is off. Editing tools are unlocked."**

## Step 2: Identify the Plan Context

Determine what was planned and where the plan document lives:

- If the plan was attached to an **existing issue** → you already have the issue ID and document
- If the plan created a **new issue** (task plan) → you already have both from `/plan`
- If the plan is a **project-level document** (feature exploration) → check whether it's now ready to become actionable (see Step 3)

## Step 3: Create or Update Linear Artifacts

### For task plans (plan attached to an issue):
The issue already exists with the plan document attached. Ensure it has the **Task** label:

```
save_issue(id: "<issue-id>", labels: ["Task"], state: "Scheduling")
```

### For feature plans becoming actionable:
If the exploration has matured into an actionable feature:

1. Create a parent issue labeled **Feature** for the feature:
```
save_issue(title: "<feature title>", team: "Technologentsia", project: "<project>", labels: ["Feature"], state: "Scheduling")
```

2. Create a new implementation plan document attached to that issue (distinct from the exploratory project document):
```
create_document(issue: "<new issue identifier>", title: "Implementation Plan: <brief description>", content: <tactical plan>)
```

3. Add a reference link to the original exploratory document on the issue:
```
save_issue(id: "<issue-id>", links: [{"url": "<exploratory doc URL>", "title": "Exploratory Plan"}])
```

### For feature explorations that are NOT yet actionable:
If the plan is purely exploratory and not ready for implementation, skip issue creation. Just confirm:
**"Exploration plan is finalized on the project. When you're ready to move this toward implementation, we can create an actionable plan and feature issue."**

## Step 4: Create Phase Sub-Issues (for phased plans)

If the plan document contains multiple implementation phases (look for "Phase 1", "Phase 2", etc. in the Implementation Steps or Approach sections), create a sub-issue for each phase as a child of the parent issue.

### Detecting phases:
Read the plan document. If the Implementation Steps section groups work into numbered phases (e.g., "Phase 1 — Backend Foundation", "Phase 2 — Accuracy Improvements"), create one sub-issue per phase.

### Sub-issue creation rules:

1. **Title format**: `Phase N: <phase title from plan>`
2. **Label**: `Task` (phases are tasks under a Feature parent)
3. **Parent**: Set `parentId` to the parent feature issue
4. **Project**: Same project as the parent
5. **Status**: Same status as the parent issue (typically Scheduling)
6. **Description**: Put the **full phase content in the issue body** — NOT as a comment. Include:
   - A brief summary of what the phase accomplishes (first paragraph)
   - Implementation steps as a numbered list
   - Key technical details from the Approach section for that phase (DTOs, code structure, patterns, etc.)
   - Files to create or modify
   - Any relevant references or UX patterns
   - Attribution signature at the bottom

### Important:
- **All phase content goes in the description (body), never as a comment.** The description is the primary content surface for an issue.
- Create all sub-issues in parallel for efficiency.
- After creating all sub-issues, move them to the same status as the parent.

### Example:
```
save_issue(
    title: "Phase 1: Backend — Hubble Fallback Stats Service",
    team: "Technologentsia",
    project: "<project>",
    labels: ["Task"],
    parentId: "<parent-issue-id>",
    description: "Create the backend service and DTOs that query...\n\n## Implementation Steps\n\n1. Create `QueryPerformanceHistory` DTO...\n\n## Key Details\n\n...\n\n---\n🤖 Claude · Session {8-char-UUID}"
)
```

## Step 5: Cascade Status to Sub-Issues

**Linear does not automatically cascade status changes from parent to child issues.** Whenever you move the parent issue to a new status, you must also move all sub-issues to the same status.

This applies in this skill (moving to Scheduling) and should be noted as a convention for other skills that move issues (e.g., `/release`, `/complete`).

After creating phase sub-issues, move them all to match the parent's status:
```
# For each sub-issue created:
save_issue(id: "<sub-issue-id>", state: "<same status as parent>")
```

Use parallel calls for efficiency.

## Step 6: Promote Parent Issue if Needed

If the issue being approved is a subtask (has a parent issue), check the parent's status. If the parent is in **Planning** or **Queueing**, move it to **Working**:

```
get_issue(id: "<issue-id>")  → check for parentId
# If parentId exists:
get_issue(id: "<parent-id>")  → check state
# If state is Planning or Queueing:
save_issue(id: "<parent-id>", state: "Working")
```

Use a **haiku subagent** for these status updates.

## Step 7: Confirm to User

Summarize what was done:
- What artifacts were created or updated
- Current status of the issue(s)
- Where the plan document lives

Close with: **"Plan is approved and artifacts are finalized. Use `/implement` (or `/implement TEC-xxx`) when you're ready to start building."**

## Important Rules

1. **Do NOT begin implementation.** This skill finalizes artifacts only. `/implement` starts the work.
2. **Create phase sub-issues for phased plans.** If the plan has multiple phases, create a sub-issue per phase with full content in the description body (not as comments). Move them to match the parent's status.
3. **Always cascade status changes to sub-issues.** Linear does not propagate status from parent to children. When moving the parent, move all children too.
4. **Use haiku subagents** for Linear write operations (status updates, label changes, link additions). Include the attribution signature on any comments posted.
5. **Use the correct status names**: Scheduling (planned/approved), Queueing (released for work), Working (in progress), Reviewing (awaiting review), Running (complete).
