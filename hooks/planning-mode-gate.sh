#!/bin/bash
# Planning Mode Gate — PreToolUse hook (tested and working)
# Blocks Edit, Write, and NotebookEdit when the current session is in planning mode.
# Planning sessions are tracked in ~/.claude/planning-sessions.json
# Format: ["session-id-1", "session-id-2"]

PLANNING_FILE="$HOME/.claude/planning-sessions.json"

# Read hook input from stdin
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id')
tool_name=$(echo "$input" | jq -r '.tool_name')

# If no planning file exists, allow everything
if [[ ! -f "$PLANNING_FILE" ]]; then
  exit 0
fi

# Check if this session is in planning mode
in_planning=$(jq -r --arg sid "$session_id" 'if type == "array" then map(select(. == $sid)) | length else 0 end' "$PLANNING_FILE" 2>/dev/null)

if [[ "$in_planning" -gt 0 ]]; then
  # Session is in planning mode — block editing tools
  case "$tool_name" in
    Edit|Write|NotebookEdit)
      # Output JSON to block the tool with a reason
      cat <<'BLOCK'
{"decision":"block","reason":"Planning mode is active. Finish your plan and get approval before editing code. Use /approve to exit planning mode."}
BLOCK
      exit 0
      ;;
  esac
fi

# Allow everything else
exit 0
