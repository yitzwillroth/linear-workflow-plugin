---
name: approve
description: Approve a plan and finalize Linear artifacts. Unlocks editing tools, creates parent issue if needed, attaches plan document, and moves to Scheduling status. Does NOT start implementation — use /implement for that.
---

# Approve Plan

The user has reviewed and approved the plan. Finalize the artifacts and unlock editing tools — but do NOT begin implementation. The user will invoke `/implement` when ready to start building.

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

## Step 4: Promote Parent Issue if Needed

If the issue being approved is a subtask (has a parent issue), check the parent's status. If the parent is in **Planning** or **Queueing**, move it to **Working**:

```
get_issue(id: "<issue-id>")  → check for parentId
# If parentId exists:
get_issue(id: "<parent-id>")  → check state
# If state is Planning or Queueing:
save_issue(id: "<parent-id>", state: "Working")
```

Use a **haiku subagent** for these status updates.

## Step 5: Confirm to User

Summarize what was done:
- What artifacts were created or updated
- Current status of the issue(s)
- Where the plan document lives

Close with: **"Plan is approved and artifacts are finalized. Use `/implement` (or `/implement TEC-xxx`) when you're ready to start building."**

## Important Rules

1. **Do NOT begin implementation.** This skill finalizes artifacts only. `/implement` starts the work.
2. **Do NOT create subtasks or checklists.** Those are created at implementation time by `/implement`.
3. **Use haiku subagents** for Linear write operations (status updates, label changes, link additions).
4. **Use the correct status names**: Scheduling (planned/approved), Queueing (released for work), Working (in progress), Reviewing (awaiting review), Running (complete).
