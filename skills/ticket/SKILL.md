---
name: ticket
description: "Capture a sidebar conversation or side quest as a Linear ticket in the backlog. Usage: /ticket or 'tick it!' during conversation. Distills recent discussion into a well-formed issue."
---

# Ticket

Capture something that came up during conversation — a side quest, a noticed improvement, a future idea — as a Linear ticket without breaking flow. This is for things that should be done but not right now.

## Attribution

Every Linear issue created must include an attribution signature at the bottom of the description:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`.

## Step 1: Identify What to Capture

### With an argument (`/ticket refactor the buffer to use Redis`):
The argument is a hint — use it along with recent conversation context to understand what to capture.

### Without an argument (`/ticket` or user said "tick it!"):
Scan the recent conversation for the sidebar discussion. Look for:
- A topic that diverged from the main task
- Something the user noticed or mused about
- An improvement idea that was discussed but explicitly deferred
- A "we should do X eventually" moment

If the conversation context is ambiguous, ask: "What should I ticket? I see we discussed [X] and [Y] — which one?"

## Step 2: Determine Placement

### Project:
Infer the Linear project from the current working directory or conversation context. If uncertain, call `list_projects` and ask.

### Status:
Default to **Scheduling** (backlog). The user can override:
- "tick it, high priority" → Scheduling + priority 2
- "tick it for this cycle" → assign to current cycle
- Any other explicit placement instruction

### Labels:
Choose one classification label based on the nature of the work: Feature, Refactor, Chore, Docs, Bug, Test, CI. Do NOT assign a hierarchy label (Epic/Story) — that's determined during planning.

### Parent:
Do not assign a parent issue unless the user explicitly says this belongs under an existing epic.

## Step 3: Write the Issue

Distill the conversation into a well-formed issue. The description should:

1. **Capture the insight** — what was discussed, what prompted it, why it matters
2. **Preserve context** — include enough background that someone (or a future agent) can pick this up cold without re-reading the conversation
3. **Note any decisions or preferences** the user expressed during the sidebar
4. **Leave open questions** explicit — things that weren't resolved in the sidebar

Do NOT include implementation steps or checklists — that's what `/plan` is for. The ticket captures *what* and *why*, not *how*.

### Title:
Craft a clear, specific title. Not the user's words verbatim — distill the intent.

### Format:

```markdown
## Objective
What needs to happen and why it matters.

## Background
What prompted this — context from the conversation, relevant codebase state.

## Open Questions
- Anything unresolved from the discussion

---
🤖 Claude · Session {8-char-UUID}
```

## Step 4: Create the Issue

Use a **haiku subagent** to create the issue:

```
save_issue(
    title: "<title>",
    team: "<team>",
    project: "<project>",
    labels: ["<classification>"],
    state: "Scheduling",
    description: "<description>"
)
```

## Step 5: Confirm

Keep it brief — the user wants to get back to what they were doing:

**"Ticketed: [HUB-NNN](url) — <title>. Sitting in Scheduling."**

If priority or cycle was specified, mention it: **"Ticketed: [HUB-NNN](url) — <title>. High priority, Scheduling."**

## Important Rules

1. **Be fast.** This skill exists to avoid breaking flow. Don't over-research or over-plan. Capture the essence and move on.
2. **Don't start planning.** The ticket captures the *what*, not the *how*. `/plan` does that later.
3. **Preserve the user's voice.** If they expressed a strong opinion or preference in the sidebar, capture it — that context is easy to lose.
4. **Default to Scheduling.** Unless told otherwise, tickets go to the backlog. The user will prioritize them later.
5. **Use haiku subagents** for the Linear write operations.
