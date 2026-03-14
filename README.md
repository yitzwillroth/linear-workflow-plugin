# Linear-Driven Development Workflow for Claude Code

A complete skill-based workflow for Claude Code that integrates with Linear for issue tracking, planning, implementation, and review. Includes session-scoped edit locking during planning mode.

## Skills

| Skill | Purpose | Status Transition |
|---|---|---|
| `/plan` | Explore codebase, write plan document to Linear | — (creates document) |
| `/approve` | Finalize artifacts, create parent issue, attach plan | → Scheduling |
| `/release` | Release planned work for implementation | Scheduling → Queueing |
| `/implement` | Break down into stories/checklists, start coding | Queueing → Working |
| `/handoff` | End-of-session: enrich artifacts, save progress | — (stays Working) |
| `/remediate` | Post organized review feedback, route back for fixes | Reviewing → Queueing |
| `/accept` | Squash merge to develop, advance cards to Running | Reviewing → Running |

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

## Issue Types & Labels

- **Initiative** — exploratory plan attached to a Linear project; ideation and architecture thinking that may spawn epics
- **Epic** — parent issue with stories (phase sub-issues) + checklists on each story
- **Story** — sub-issue of an epic, representing one phase of implementation
- **Task** — standalone issue with checklists directly (no sub-issues)
- **Remediation** — needs fixes from review; prioritized over fresh work

## Installation

### As a Claude Code plugin

If your team management tool supports Claude Code plugins, point it at this repo's URL:

```
https://github.com/yitzwillroth/linear-workflow-plugin
```

### Manual installation

1. Clone this repo
2. Copy each `skills/<name>/SKILL.md` into `~/.claude/skills/<name>/SKILL.md`
3. Copy `hooks/planning-mode-gate.sh` and `hooks/planning-mode-toggle.sh` into `~/.claude/hooks/`
4. Make the hooks executable: `chmod +x ~/.claude/hooks/planning-mode-*.sh`
5. Register the gate hook in your `~/.claude/settings.json`:

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

## First-Time Setup

### 1. Set your Linear team name

The skills use `YOUR_TEAM` as a placeholder for Linear API calls. Find and replace it with your actual Linear team name:

```bash
# From the plugin directory (or wherever your SKILL.md files live):
sed -i '' 's/YOUR_TEAM/My Team Name/g' skills/*/SKILL.md
```

Or if installed manually under `~/.claude/skills/`:

```bash
sed -i '' 's/YOUR_TEAM/My Team Name/g' ~/.claude/skills/{plan,approve,implement}/SKILL.md
```

### 2. Create Linear labels

Create these labels in your Linear workspace:
- **Epic**
- **Story**
- **Task**
- **Remediation**

### 3. Create custom statuses

Create these custom statuses on your Linear team:

| Status | Type |
|---|---|
| Planning | Backlog |
| Scheduling | Unstarted |
| Queueing | Unstarted |
| Working | Started |
| Reviewing | Started |
| Running | Completed |
| Canceled | Canceled |

### 4. Connect the Linear MCP server

Install the [Linear MCP server](https://github.com/linear/linear-mcp) so Claude Code can read and write Linear issues.

## Key Design Decisions

- **Planning and implementation are separate sessions** by default. `/approve` finalizes artifacts but does NOT start coding. `/implement` starts a fresh session with full context window.
- **TodoWrite and Linear checklists are the same information** — composed once, posted to both. Near-zero marginal cost.
- **Use haiku subagents** for all Linear write operations to save tokens. Opus reads and composes, haiku executes CRUD.
- **`/accept` requires human initiation** — the agent performs the merge mechanics, but only after the human explicitly invokes `/accept`.
- **Remediation items are prioritized** over fresh work when agent picks from the board.
- **Cross-session continuity** via Linear: `/implement HUB-xxx` in a new session reads plan + checklists to reconstruct state.

## Dependencies

- [Linear MCP server](https://github.com/linear/linear-mcp) for Linear integration
- `jq` for the planning mode hooks
- Claude Code with skills support
