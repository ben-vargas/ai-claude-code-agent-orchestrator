#!/bin/bash
# Tool usage tracking hook for Claude Code
# Tracks all tool usage by agents with timing and success metrics

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
SESSION_ID=${CLAUDE_SESSION_ID:-"default"}
BACKUP_LOG="$HOME/.claude/agent-tracking-backup/tool-usage.log"

# Ensure backup directory exists
mkdir -p "$(dirname "$BACKUP_LOG")"

# Source Slack integration
source "$(dirname "$0")/slack-integration.sh" 2>/dev/null || true

# Function to log to SQLite
log_tool_usage() {
    local start_time="$1"
    local success="$2"
    local error_msg="$3"
    local result_summary="$4"
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    # Mask sensitive data in parameters
    SAFE_PARAMS=$(echo "$CLAUDE_TOOL_PARAMS" | sed -E '
        s/"password":"[^"]*"/"password":"***"/g
        s/"token":"[^"]*"/"token":"***"/g
        s/"api_key":"[^"]*"/"api_key":"***"/g
        s/"secret":"[^"]*"/"secret":"***"/g
    ')
    
    # Escape single quotes for SQL
    error_msg=$(echo "$error_msg" | sed "s/'/''/g")
    result_summary=$(echo "$result_summary" | sed "s/'/''/g")
    
    # Log to SQLite
    sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_tool_usage (
    agent_id, tool_name, tool_parameters, 
    execution_start, execution_end, execution_duration_ms,
    success, error_message, result_summary,
    task_context, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    '${CLAUDE_TOOL_NAME:-unknown}', 
    '$SAFE_PARAMS',
    datetime('$TIMESTAMP'), 
    datetime('now'), 
    $duration,
    $success, 
    '$error_msg', 
    '$result_summary',
    '${CLAUDE_TASK_ID:-}', 
    '$SESSION_ID'
);
EOF
    
    # Also log to backup file
    echo "[$TIMESTAMP] Agent:$CLAUDE_AGENT_ID Tool:$CLAUDE_TOOL_NAME Success:$success Duration:${duration}ms" >> "$BACKUP_LOG"
}

# Update session statistics
update_session_stats() {
    local increment_field="$1"
    
    sqlite3 "$MEMORY_DB" << EOF
UPDATE hook_agent_sessions 
SET $increment_field = $increment_field + 1
WHERE session_id = '$SESSION_ID' 
  AND agent_id = '${CLAUDE_AGENT_ID:-unknown}';

-- Create session if doesn't exist
INSERT OR IGNORE INTO hook_agent_sessions (session_id, agent_id)
VALUES ('$SESSION_ID', '${CLAUDE_AGENT_ID:-unknown}');
EOF
}

# Main hook logic
case "${1:-$CLAUDE_HOOK_EVENT}" in
    "tool.before")
        # Record tool start
        echo $(date +%s%3N) > "/tmp/claude-tool-start-$$.time"
        echo "[$TIMESTAMP] TOOL_START: Agent=$CLAUDE_AGENT_ID Tool=$CLAUDE_TOOL_NAME" >> "$BACKUP_LOG"
        ;;
        
    "tool.after")
        # Record tool completion
        START_TIME=$(cat "/tmp/claude-tool-start-$$.time" 2>/dev/null || echo $(date +%s%3N))
        rm -f "/tmp/claude-tool-start-$$.time"
        
        # Extract result summary (first 200 chars)
        RESULT_SUMMARY=$(echo "${CLAUDE_TOOL_RESULT:-Success}" | head -c 200 | tr '\n' ' ')
        
        log_tool_usage "$START_TIME" "1" "" "$RESULT_SUMMARY"
        update_session_stats "total_tools_used"
        ;;
        
    "tool.error")
        # Record tool failure
        START_TIME=$(cat "/tmp/claude-tool-start-$$.time" 2>/dev/null || echo $(date +%s%3N))
        rm -f "/tmp/claude-tool-start-$$.time"
        
        ERROR_MSG=$(echo "${CLAUDE_ERROR_MESSAGE:-Unknown error}" | tr '\n' ' ')
        log_tool_usage "$START_TIME" "0" "$ERROR_MSG" ""
        update_session_stats "total_errors"
        
        # Also log to error events for pattern analysis
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_error_events (
    agent_id, error_type, error_message, error_context,
    impact_level, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    'tool_failure', 
    '$ERROR_MSG',
    '{"tool": "${CLAUDE_TOOL_NAME:-unknown}", "params": $SAFE_PARAMS}',
    'medium', 
    '$SESSION_ID'
);
EOF
        
        echo "[$TIMESTAMP] TOOL_ERROR: Agent=$CLAUDE_AGENT_ID Tool=$CLAUDE_TOOL_NAME Error=$ERROR_MSG" >> "$BACKUP_LOG"
        
        # Send Slack notification for tool errors
        notify_slack "tool.error" "${CLAUDE_AGENT_ID:-unknown}" \
            "$(format_tool_error "${CLAUDE_TOOL_NAME:-unknown}" "$ERROR_MSG")" \
            "medium"
        ;;
        
    "test")
        # Test mode
        echo "Tool usage hook is working!"
        echo "Would log to: $MEMORY_DB"
        echo "Backup log at: $BACKUP_LOG"
        if is_slack_enabled; then
            echo "Slack notifications: ENABLED"
        else
            echo "Slack notifications: DISABLED"
        fi
        ;;
esac