---
name: approve
description: Approve a plan and materialize it into Linear issues. Unlocks editing tools, creates epic/stories or story+checklist from plan content, and moves to Scheduling. Does NOT start implementation — use /implement for that.
---

# Approve Plan

The user has reviewed and approved the plan. Materialize it into actionable Linear issues and unlock editing tools — but do NOT begin implementation. The user will invoke `/implement` when ready to start building.

## Attribution

Every Linear comment and issue update must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Deactivate Planning Mode

Run this command to deactivate planning mode:

```bash
~/.claude/hooks/planning-mode-toggle.sh deactivate
```

After unlocking, confirm: **"Planning mode is off. Editing tools are unlocked."**

## Step 2: Read and Understand the Plan

Read the plan document created during `/plan`. Identify:

- **The objective** — what we're setting out to achieve
- **The implementation steps** — the concrete work to be done
- **Decisions made** — constraints and choices from the planning conversation
- **Open questions** — anything still unresolved (raise with user before proceeding)

Also assess **scale**: Is this work complex enough to warrant an epic with stories, or is it a single story with a checklist?

### Scale heuristic (planner's judgment):

- **Epic + stories**: Multiple distinct deliverables, work spans different areas of the codebase, steps are independently meaningful and could be picked up separately.
- **Single story + checklist**: One cohesive piece of work, steps are sequential and tightly coupled, a single agent could do it in one session.

If uncertain, ask: "This plan has N steps. Should I create an epic with stories, or a single story with a checklist?"

## Step 3: Determine Plan Type

### For initiative plans (project-level explorations):

If the plan is purely exploratory and not ready for implementation, skip issue creation. Confirm:
**"Initiative is finalized on the project. When you're ready to move this toward implementation, we can create an actionable plan and epic."**

If the initiative is now ready to become actionable, proceed to Step 4.

### For implementation plans:

Proceed to Step 4. The plan document is a temporal artifact — the issues you create next become the source of truth.

### For existing issue plans (`/plan HUB-12`):

The issue already exists. Skip issue creation in Step 4 and go directly to Step 5 to populate it with stories or a checklist.

## Step 4: Create the Issue Structure

### Epic path (multi-story work):

1. **Create the epic issue.** The description captures **what we're setting out to achieve** — the objective, not the how. Include context that helps someone understand the scope and motivation.

```
save_issue(
    title: "<epic title>",
    team: "HubbleOps",
    project: "<project>",
    labels: ["Epic"],
    state: "Scheduling",
    description: "<objective and context — what and why, not how>"
)
```

2. **Attach the plan document to the epic** so it's findable as historical context:

```
create_attachment(issueId: "<epic-id>", url: "<plan-document-url>", title: "Planning Document (superseded by stories)")
```

3. **Create stories as sub-issues.** Each story is self-contained — an implementer should be able to pick it up cold without reading the plan document. Use planner's judgment to group plan steps into stories.

For each story:

```
save_issue(
    title: "<story title>",
    team: "HubbleOps",
    project: "<project>",
    labels: ["Story", "<classification>"],
    parentId: "<epic-id>",
    state: "Scheduling",
    description: "<see story content format below>"
)
```

**Classification labels** map to conventional commit types: Feature, Bug, Refactor, Chore, Docs, Test, CI.

### Story-only path (single story with checklist):

Create a single story. The description captures **what** we want to do. The checklist captures **how**.

```
save_issue(
    title: "<story title>",
    team: "HubbleOps",
    project: "<project>",
    labels: ["Story", "<classification>"],
    state: "Scheduling",
    description: "<see story content format below>"
)
```

If the story belongs to an existing epic, set `parentId` accordingly and attach the plan document to the epic.

## Step 5: Write Self-Contained Story Descriptions

Each story description must be **self-contained** — all context needed to implement it, drawn from the plan. An agent picking up this story should not need to read the plan document.

### Story description format (epic stories):

```markdown
## Objective
What this story accomplishes and why it matters in the context of the epic.

## Background
Relevant context: what exists today, key findings from planning, constraints.

## Approach
How to implement this. Be specific about:
- Which files to create or modify
- Which patterns to follow (reference existing code)
- Key design decisions and why

## Checklist
- [ ] Highly granular step 1
- [ ] Highly granular step 2
- [ ] Highly granular step 3
...

## Test Strategy
How to verify this story's work.

---
🤖 Claude · Session {8-char-UUID}
```

**Checklists on stories within an epic must be highly granular.** Each checkbox should represent a single, independently verifiable action — not "implement the feature" but "create the DTO class", "add the migration", "write the factory", etc.

### Story description format (standalone story with checklist):

```markdown
## Objective
What we want to do and why.

## Checklist
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3
...

---
🤖 Claude · Session {8-char-UUID}
```

For standalone stories, the checklist can be less granular than epic stories — use judgment based on complexity.

## Step 6: Cascade Status

**Linear does not automatically cascade status changes from parent to child issues.** After creating all stories, ensure they all match the parent's status (Scheduling).

Move all sub-issues to Scheduling in parallel:
```
save_issue(id: "<sub-issue-id>", state: "Scheduling")
```

## Step 7: Promote Parent Issue if Needed

If the issue being approved is a story within an existing epic, check the parent's status. If the parent is in **Planning** or **Queuing**, move it to **Working**:

```
get_issue(id: "<issue-id>")  → check for parentId
# If parentId exists:
get_issue(id: "<parent-id>")  → check state
# If state is Planning or Queuing:
save_issue(id: "<parent-id>", state: "Working")
```

Use a **haiku subagent** for these status updates.

## Step 8: Confirm to User

Summarize what was created:
- Epic and/or stories created (with links)
- Current status (Scheduling)
- Where the plan document lives (attached to epic, superseded by stories)

Close with: **"Plan is approved. [N] stories created in Scheduling. The plan document is attached to the epic for reference but the stories are now the source of truth. Use `/implement` (or `/implement HUB-xxx`) when you're ready to start building, or `/release HUB-xxx` to release individual stories for work."**

## Important Rules

1. **Do NOT begin implementation.** This skill materializes plan content into issues only. `/implement` starts the work.
2. **Stories are the source of truth.** Every story must be self-contained — all context needed to implement, not a pointer back to the plan.
3. **Checklists on epic stories must be highly granular.** Each checkbox = one verifiable action.
4. **The plan document is superseded, not deleted.** Attach it to the epic for historical reference, but the stories drive execution.
5. **Always cascade status changes to sub-issues.** Linear does not propagate status from parent to children. When moving the parent, move all children too.
6. **Use haiku subagents** for Linear write operations (status updates, label changes). Include the attribution signature on any comments posted.
7. **Use the correct status names**: Scheduling (planned/approved), Queuing (released for work), Working (in progress), Reviewing (awaiting review), Running (complete).
8. **Use planner's judgment on granularity.** Not every plan step needs its own story. Group or split as appropriate.
