---
name: plan
description: Enter custom planning mode. Locks editing tools, guides thorough codebase exploration, and writes the plan to a Linear document. Invoke with /plan TEC-12, /plan hubble, or just /plan. Supports an optional prompt after the target.
---

# Custom Planning Mode

You are entering planning mode. Your job is to **explore thoroughly and think deeply** before proposing any implementation. You are NOT allowed to write code until the user explicitly approves your plan.

## Attribution

Every Linear document and comment created during planning must include an attribution signature:

```
---
🤖 Claude · Session {first-8-chars-of-session-UUID}
```

Derive the session UUID from the most recently modified JSONL transcript file in `~/.claude/projects/`. Include this at the bottom of plan documents and any comments posted.

## Step 1: Lock Editing Tools

Run this command immediately to activate the planning gate:

```bash
~/.claude/hooks/planning-mode-toggle.sh activate
```

After running this, confirm to the user: **"Planning mode is active. I can explore and read but cannot edit code until you approve the plan."**

## Step 2: Parse Arguments

Parsing is positional. Use these rules in order — stop at the first match.

### Parsing rules:

1. **No arguments** (`/plan`) → ask what to plan.

2. **First token matches issue identifier** (`XXX-123` — letters, dash, numbers) → **issue mode**. Fetch the issue with `get_issue`. Everything after the identifier is the **prompt**.

3. **First token matches a Linear project name** → call `list_projects` to confirm the match. Everything after the project name is the **prompt**.

4. **First token matches neither an issue ID nor a known project** → treat the **entire argument string** as a prompt. Call `list_projects` to check for close matches (typos, slugs). Then ask the user: "Which project does this belong to?"

### Examples:

| Input | Target | Prompt |
|---|---|---|
| `/plan TEC-12 refactor the buffer to use Redis` | Issue TEC-12 | "refactor the buffer to use Redis" |
| `/plan hubble add rate limiting` | Project hubble | "add rate limiting" |
| `/plan hubble` | Project hubble | (none — explore and ask) |
| `/plan add rate limiting to the buffer` | **ask project** | "add rate limiting to the buffer" |
| `/plan` | (none) | (none — ask everything) |

### Determining plan placement:

The user tells you where the plan goes and what kind of work this is. Don't assume. If context makes it obvious (e.g., `/plan TEC-12` is clearly an issue-level plan), proceed. Otherwise, ask:

- "Should this be an exploratory document on the project, or a tactical implementation plan on an issue?"

**Exploratory plans** (project-level documents): Broader explorations, architecture decisions, feature-level thinking that may spawn tasks later. These attach to the Linear project.

**Implementation plans** (issue-level documents): Tactical plans for specific work. These attach to a Linear issue. If no issue exists yet, you'll create one.

### What to do with the prompt:
The prompt is the user's initial direction. It replaces the "ask what to plan" step — you already know what they want. Use it as your starting context alongside any relevant conversation history. You still explore thoroughly; the prompt just gives you a head start.

**You are still responsible for the title.** The prompt informs your understanding but isn't used verbatim as a title. The title emerges from conversation and exploration.

### Resolving projects:
Always call `list_projects` on Linear to confirm project names. Do not guess or infer from the working directory. Project matching is case-insensitive.

### For existing issues (`TEC-12`):
Fetch the issue with `get_issue` to understand the task. The issue description plus any prompt is your starting context.

### For new implementation plans (create issue + plan):
Use the prompt and conversation to understand what's being planned. Explore the codebase. When writing the plan, also create the issue with `save_issue` using a title that captures what you learned. Attach the plan doc to that issue.

### For exploratory plans (project-level):
Use the prompt and conversation to understand the scope. Explore the codebase. Before creating the document, check for existing documents (see Step 5). Create a plan doc attached to the project.

## Step 3: Gather Context

Before exploring the codebase, assess what context you already have. This step is critical — the user may invoke `/plan` after a long conversation, and relevant discussion should carry forward into the plan.

### Context assessment:

1. **Scan the conversation history** for content relevant to the plan target. Relevance is determined by the plan target, not by recency — something from an hour ago may be critical, something from 2 minutes ago may be irrelevant.

2. **Look for decisions already made** — statements like "let's use Redis for this", "I don't want a new migration", "keep it simple" are constraints that must carry into the plan. Don't re-ask questions the user already answered.

3. **Look for exploration already done** — if you already read through files, discussed architecture, or identified patterns during the conversation, reference what you learned rather than re-reading everything.

4. **Look for rejected approaches** — if the user said "I don't want to do it that way", don't propose it in the plan.

5. **Ignore unrelated work** — if the first half of the conversation was fixing CSS and now the user is planning a new recorder, the CSS discussion isn't context.

6. **When uncertain, briefly state what you're carrying forward** — "I'm incorporating our earlier discussion about X and Y. Anything else I should factor in, or anything I should set aside?" Keep this short — don't recite the entire conversation back.

### Cold start (no prior conversation context):

If `/plan` is invoked with minimal context (fresh session, or the conversation so far was about unrelated things):

- **Issue with good description** → the issue description is your context, explore from there
- **Plan with no prior discussion** → ask 2-3 focused clarifying questions before exploring: What's the scope? What triggered this? Any known constraints?
- **No arguments at all** → ask what they want to plan

## Step 4: Explore Thoroughly

This is the most important step. **Do not rush to write a plan.** Your goal is to deeply understand the codebase before proposing anything. However, don't re-explore things you already understand from the conversation context.

### Exploration checklist:

1. **Understand the request** — What exactly needs to happen? What are the acceptance criteria?
2. **Find existing patterns** — How does the codebase handle similar things today? Use Serena LSP (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`) for structural navigation. Use ColGrep for behavioral/intent queries when you don't know what to search for.
3. **Identify all touchpoints** — Which files, classes, methods, configs, tests, and migrations will be affected?
4. **Check for constraints** — Are there architectural rules (check `ArchTest.php`)? Database limitations (SQLite in tests)? Convention requirements?
5. **Look for prior art** — Has something similar been attempted before? Are there related TODOs, comments, or partial implementations?
6. **Consider the test strategy** — How will this be tested? What fixtures or factories are needed?

### Tools you SHOULD use heavily:
- `find_symbol` / `get_symbols_overview` / `find_referencing_symbols` (Serena LSP)
- `colgrep` via Bash (semantic code search)
- `Read` (read files thoroughly)
- `Grep` / `Glob` (exact matches, file patterns)
- `Agent` with explore subagent (for deep dives)
- Linear tools (read issues, check related tasks)

### Tools you CANNOT use (the hook will block them):
- `Edit` — blocked
- `Write` — blocked
- `NotebookEdit` — blocked

If you try to use them, you'll get a block message. This is intentional.

## Step 5: Write the Plan to Linear

Once you've explored enough to have a clear picture, create or update a Linear document with the plan.

### Check for existing documents first:

**For exploratory plans (project-attached):**
Before creating a new document, call `list_documents(project: "<project>")` and scan the titles for anything relevant to what you're planning. If a document looks like it covers the same topic:
- Ask: "I found **[title]** on this project. Should I update that document, or create a new one?"
- If the user says update → use `update_document` with the existing document's ID
- If the user says create new → proceed with `create_document`
- If nothing matches → create a new document without asking

**For implementation plans (issue-attached):**
Check if the issue already has a plan document. If it does, update it with `update_document` rather than creating a duplicate. If it doesn't, create a new one.

### Creating new plans:

**For implementation plans (create issue + plan):**
```
save_issue(title: "<title from conversation>", team: "Technologentsia", project: "<project>", labels: ["Task"])
create_document(issue: "<new issue identifier>", title: "Plan: <brief description>", content: <plan>)
```

For features, use the `Feature` label instead of `Task`.

**For exploratory plans (project-attached):**
```
create_document(project: "<project>", title: "Exploration: <brief description>", content: <plan>)
```

**For existing issue plans:**
```
create_document(issue: "TEC-12", title: "Plan: <brief description>", content: <plan>)
```

### Plan document structure:

```markdown
## Objective
What we're trying to accomplish and why.

## Background
What exists today that's relevant. Key findings from exploration.
Include relevant context from the conversation if applicable.

## Approach
The proposed implementation strategy. Be specific about:
- Which files to create or modify
- Which patterns to follow (reference existing code)
- Key design decisions and why

## Implementation Steps
Numbered steps in the order they should be executed.
Each step should be concrete enough to act on.
Group steps into phases if the work is complex enough to warrant it.

## Test Strategy
How this will be tested. Which test files, what scenarios.

## Open Questions
Anything unresolved that needs input before starting.

---
🤖 Claude · Session {8-char-UUID}
```

After creating or updating the document, share the URL with the user and say:

**"Plan is ready for review: [link]. Let me know when you'd like to approve it, suggest changes, or discuss any part of it. Use `/approve` when you're ready to finalize the artifacts."**

## Important Behavioral Rules

1. **Do not ask to exit planning mode yourself.** Only the user can approve.
2. **Do not try to work around the edit block.** The constraint exists to keep you in exploration mode.
3. **Spend more time exploring than you think you need.** The whole point of planning mode is to prevent premature coding.
4. **If the user gives feedback on the plan**, update the Linear document — you can do this because `update_document` is not blocked, only code editing tools are.
5. **If you realize the plan is wrong while writing it**, go back and explore more. Don't commit to a bad plan just because you started writing.
6. **Honor decisions from the conversation.** If the user already expressed preferences, constraints, or rejected approaches during the conversation, respect those in the plan without re-litigating them.
7. **You own the titles.** The user doesn't provide issue or document titles — you craft them based on what you learned from the conversation and exploration. Make them clear and specific.
8. **Always resolve projects live.** Call `list_projects` to confirm project names — never guess or infer from the working directory.
