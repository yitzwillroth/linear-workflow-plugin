# Linear-Driven Development Workflow for Claude Code

A complete skill-based workflow for Claude Code that integrates with Linear for issue tracking, planning, implementation, and review. Includes session-scoped edit locking during planning mode.

## Skills

| Skill | Purpose | Status Transition |
|---|---|---|
| `/plan` | Explore codebase, write plan document to Linear | — (creates document) |
| `/approve` | Finalize artifacts, create parent issue, attach plan | → Scheduling |
| `/release` | Release planned work for implementation | Scheduling → Queueing |
| `/implement` | Break down into subtasks/checklists, start coding | Queueing → Working |
| `/handoff` | End-of-session: enrich artifacts, save progress | — (stays Working) |
| `/remediate` | Post organized review feedback, route back for fixes | Reviewing → Queueing |
| `/complete` | Mark as Running after human review | Reviewing → Running |

## Board Columns (Linear)

```
Planning → Scheduling → Queueing → Working → Reviewing → Running
```

- **Planning**: Idea dump, unrefined
- **Scheduling**: Planned & approved, not released for implementation
- **Queueing**: Released — agent can pick these up
- **Working**: Actively being implemented
- **Reviewing**: Complete, awaiting human review
- **Running**: Human reviewed and approved

## Labels

- **Feature** — issue with subtasks (phases) + checklists on subtasks (steps)
- **Task** — issue with checklists directly (no subtasks)
- **Remediation** — needs fixes from review; prioritized over fresh work

## Installation

### 1. Create skill directories

```bash
mkdir -p ~/.claude/skills/{plan,approve,implement,handoff,remediate,complete,release}
```

### 2. Copy skill files

Place each `*-SKILL.md` file as `SKILL.md` in its corresponding directory:

```bash
# Example for plan:
cp plan-SKILL.md ~/.claude/skills/plan/SKILL.md
cp approve-SKILL.md ~/.claude/skills/approve/SKILL.md
cp implement-SKILL.md ~/.claude/skills/implement/SKILL.md
cp handoff-SKILL.md ~/.claude/skills/handoff/SKILL.md
cp remediate-SKILL.md ~/.claude/skills/remediate/SKILL.md
cp complete-SKILL.md ~/.claude/skills/complete/SKILL.md
cp release-SKILL.md ~/.claude/skills/release/SKILL.md
```

### 3. Install the planning mode hooks

```bash
mkdir -p ~/.claude/hooks
cp planning-mode-toggle.sh ~/.claude/hooks/
cp planning-mode-gate.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/planning-mode-toggle.sh
chmod +x ~/.claude/hooks/planning-mode-gate.sh
```

### 4. Register the gate hook

Add to your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/planning-mode-gate.sh"
          }
        ]
      }
    ]
  }
}
```

### 5. Linear setup

- Create **Feature**, **Task**, and **Remediation** labels
- Create custom statuses: **Planning** (backlog), **Scheduling** (unstarted), **Queueing** (unstarted), **Working** (started), **Reviewing** (started), **Running** (completed), **Canceled** (canceled)
- The workflow assumes a team named "Technologentsia" — update skill files to match your team name

## Key Design Decisions

- **Planning and implementation are separate sessions** by default. `/approve` finalizes artifacts but does NOT start coding. `/implement` starts a fresh session with full context window.
- **TodoWrite and Linear checklists are the same information** — composed once, posted to both. Near-zero marginal cost.
- **Use haiku subagents** for all Linear write operations to save tokens. Opus reads and composes, haiku executes CRUD.
- **Agent never moves issues to Running** — human in the loop required.
- **Remediation items are prioritized** over fresh work when agent picks from the board.
- **Cross-session continuity** via Linear: `/implement TEC-xxx` in a new session reads plan + checklists to reconstruct state.

## Dependencies

- [Linear MCP server](https://github.com/linear/linear-mcp) for Linear integration
- `jq` for the planning mode hooks
- Claude Code with skills support
