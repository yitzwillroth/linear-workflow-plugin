#!/bin/bash
# Planning Mode Toggle — used by /plan and /plan-approve skills
# Usage: planning-mode-toggle.sh activate
#        planning-mode-toggle.sh deactivate

ACTION="$1"
PLANNING_FILE="$HOME/.claude/planning-sessions.json"
PROJECT_DIR="$HOME/.claude/projects"

# Find the most recently modified transcript to get session ID
TRANSCRIPT=$(ls -t "$PROJECT_DIR"/*/*.jsonl 2>/dev/null | head -1)
SESSION_ID=$(basename "$TRANSCRIPT" .jsonl)

if [[ -z "$SESSION_ID" ]]; then
  echo "ERROR: Could not determine session ID"
  exit 1
fi

case "$ACTION" in
  activate)
    if [[ -f "$PLANNING_FILE" ]]; then
      jq --arg sid "$SESSION_ID" 'if index($sid) then . else . + [$sid] end' "$PLANNING_FILE" > /tmp/planning-tmp.json
      mv /tmp/planning-tmp.json "$PLANNING_FILE"
    else
      jq -n --arg sid "$SESSION_ID" '[$sid]' > "$PLANNING_FILE"
    fi
    echo "✅ Planning mode activated for session $SESSION_ID"
    echo "Edit/Write/NotebookEdit tools are now blocked."
    ;;
  deactivate)
    if [[ -f "$PLANNING_FILE" ]]; then
      jq --arg sid "$SESSION_ID" 'map(select(. != $sid))' "$PLANNING_FILE" > /tmp/planning-tmp.json
      mv /tmp/planning-tmp.json "$PLANNING_FILE"
      echo "✅ Planning mode deactivated for session $SESSION_ID"
      echo "Edit/Write/NotebookEdit tools are now unlocked."
    else
      echo "⚠️ No planning sessions file found — editing was already unlocked."
    fi
    ;;
  *)
    echo "Usage: planning-mode-toggle.sh [activate|deactivate]"
    exit 1
    ;;
esac
