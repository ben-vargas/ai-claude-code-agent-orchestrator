#!/bin/bash
# Error recovery tracking hook for Claude Code
# Attempts to identify and recover from common errors

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
SESSION_ID=${CLAUDE_SESSION_ID:-"default"}
ERROR_LOG="$HOME/.claude/agent-tracking-backup/errors.log"

# Ensure backup directory exists
mkdir -p "$(dirname "$ERROR_LOG")"

# Source Slack integration
source "$(dirname "$0")/slack-integration.sh" 2>/dev/null || true

# Escape SQL strings
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

# Determine error recovery strategy
get_recovery_strategy() {
    local error_msg="$1"
    local error_type="$2"
    
    case "$error_msg" in
        *"permission denied"*)
            echo "permission_fix|Request elevated permissions or change file ownership"
            ;;
        *"command not found"*|*"No such file or directory"*command*)
            echo "install_tool|Install missing command or tool"
            ;;
        *"No such file or directory"*)
            echo "create_file|Create missing file or directory"
            ;;
        *"connection refused"*|*"timeout"*)
            echo "retry_network|Retry after network delay"
            ;;
        *"ENOSPC"*|*"No space left"*)
            echo "free_space|Free up disk space"
            ;;
        *"already exists"*)
            echo "use_existing|Use existing resource or rename"
            ;;
        *"not a git repository"*)
            echo "init_git|Initialize git repository"
            ;;
        *"npm ERR"*|*"node_modules"*)
            echo "npm_fix|Run npm install or clear cache"
            ;;
        *"Module not found"*|*"Cannot find module"*)
            echo "install_dependency|Install missing dependency"
            ;;
        *"syntax error"*)
            echo "fix_syntax|Review and fix syntax error"
            ;;
        *)
            echo "unknown|No automatic recovery available"
            ;;
    esac
}

# Extract missing resource from error
extract_missing_resource() {
    local error_msg="$1"
    local resource=""
    
    # Try to extract command name
    if [[ "$error_msg" =~ command\ not\ found:\ ([a-zA-Z0-9_-]+) ]]; then
        resource="${BASH_REMATCH[1]}"
    # Try to extract file path
    elif [[ "$error_msg" =~ No\ such\ file\ or\ directory.*[\'\"]\/?([^\'\"]+)[\'\"] ]]; then
        resource="${BASH_REMATCH[1]}"
    # Try to extract module name
    elif [[ "$error_msg" =~ Cannot\ find\ module\ [\'\"]([^\'\"]+)[\'\"] ]]; then
        resource="${BASH_REMATCH[1]}"
    fi
    
    echo "$resource"
}

# Log error event
log_error_event() {
    local error_type="$1"
    local error_msg="$2"
    local impact="$3"
    local recovery_strategy="$4"
    local recovery_details="$5"
    
    # Log to SQLite
    sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_error_events (
    agent_id, error_type, error_message, error_context,
    impact_level, recovery_attempted, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}',
    '$(escape_sql "$error_type")',
    '$(escape_sql "$error_msg")',
    '{"task": "${CLAUDE_TASK_ID:-}", "context": "${CLAUDE_ERROR_CONTEXT:-}"}',
    '$impact',
    0,
    '$SESSION_ID'
);
EOF
    
    # Get the event ID
    local event_id=$(sqlite3 "$MEMORY_DB" "SELECT last_insert_rowid();")
    
    # Log to file
    echo "[$TIMESTAMP] ERROR: Agent=${CLAUDE_AGENT_ID:-unknown} Type=$error_type Impact=$impact" >> "$ERROR_LOG"
    echo "  Message: $error_msg" >> "$ERROR_LOG"
    echo "  Recovery: $recovery_strategy - $recovery_details" >> "$ERROR_LOG"
    
    echo "$event_id"
}

# Attempt recovery
attempt_recovery() {
    local event_id="$1"
    local strategy="$2"
    local details="$3"
    local missing_resource="$4"
    
    # Update error event with recovery attempt
    sqlite3 "$MEMORY_DB" << EOF
UPDATE hook_error_events 
SET recovery_attempted = 1,
    error_context = json_set(error_context, 
        '$.recovery_strategy', '$(escape_sql "$strategy")',
        '$.recovery_details', '$(escape_sql "$details")',
        '$.missing_resource', '$(escape_sql "$missing_resource")'
    )
WHERE event_id = $event_id;
EOF
    
    # Record missing capability if applicable
    case "$strategy" in
        "install_tool"|"install_dependency")
            if [ -n "$missing_resource" ]; then
                sqlite3 "$MEMORY_DB" << EOF
INSERT INTO missing_capabilities (
    capability_type, capability_name, requested_by_agent,
    task_context, impact_level
) VALUES (
    'tool', 
    '$(escape_sql "$missing_resource")',
    '${CLAUDE_AGENT_ID:-unknown}',
    '{"error_event_id": $event_id, "strategy": "$strategy"}',
    'high'
);
EOF
                echo "[$TIMESTAMP] MISSING_CAPABILITY: $missing_resource" >> "$ERROR_LOG"
            fi
            ;;
            
        "permission_fix")
            # Log permission issue for admin attention
            sqlite3 "$MEMORY_DB" << EOF
INSERT INTO approval_queue (
    action_type, action_details, requested_by,
    safety_score, risk_assessment
) VALUES (
    'permission_change',
    '{"resource": "$(escape_sql "$missing_resource")", "error_id": $event_id}',
    '${CLAUDE_AGENT_ID:-unknown}',
    0.9,
    '{"risk": "low", "reason": "permission_denied_error"}'
);
EOF
            ;;
    esac
}

# Check for error patterns
check_error_patterns() {
    local agent_id="${CLAUDE_AGENT_ID:-unknown}"
    
    # Check if this error is recurring
    local similar_errors=$(sqlite3 "$MEMORY_DB" "
        SELECT COUNT(*) 
        FROM hook_error_events 
        WHERE agent_id = '$agent_id' 
          AND error_message LIKE '%$(escape_sql "${CLAUDE_ERROR_MESSAGE:0:50}")%'
          AND timestamp > datetime('now', '-1 hour')
    ")
    
    if [ "$similar_errors" -gt 3 ]; then
        echo "[$TIMESTAMP] PATTERN_DETECTED: Recurring error for $agent_id" >> "$ERROR_LOG"
        
        # Send performance alert for recurring errors
        notify_slack "performance.alert" "$agent_id" \
            "Recurring error pattern detected: ${CLAUDE_ERROR_MESSAGE:0:50} (${similar_errors}x in last hour)" \
            "high"
        
        # Escalate if pattern detected
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO missing_capabilities (
    capability_type, capability_name, requested_by_agent,
    task_context, impact_level, frequency
) VALUES (
    'error_pattern',
    'recurring_$(escape_sql "${CLAUDE_ERROR_TYPE:-error}")',
    '$agent_id',
    '{"pattern": "$(escape_sql "${CLAUDE_ERROR_MESSAGE:0:100}")", "count": $similar_errors}',
    'critical',
    $similar_errors
)
ON CONFLICT(capability_type, capability_name, requested_by_agent) 
DO UPDATE SET 
    frequency = frequency + 1,
    last_requested = CURRENT_TIMESTAMP;
EOF
    fi
}

# Main error handling logic
case "${1:-$CLAUDE_HOOK_EVENT}" in
    "error.captured")
        ERROR_MSG=$(escape_sql "${CLAUDE_ERROR_MESSAGE:-Unknown error}")
        ERROR_TYPE="${CLAUDE_ERROR_TYPE:-general_error}"
        IMPACT="${CLAUDE_ERROR_IMPACT:-medium}"
        
        # Get recovery strategy
        IFS='|' read -r strategy details <<< $(get_recovery_strategy "$ERROR_MSG" "$ERROR_TYPE")
        
        # Extract missing resource
        missing_resource=$(extract_missing_resource "$ERROR_MSG")
        
        # Log error
        event_id=$(log_error_event "$ERROR_TYPE" "$ERROR_MSG" "$IMPACT" "$strategy" "$details")
        
        # Attempt recovery
        if [ "$strategy" != "unknown" ]; then
            attempt_recovery "$event_id" "$strategy" "$details" "$missing_resource"
        fi
        
        # Check for patterns
        check_error_patterns
        
        # Send Slack notification based on impact
        case "$IMPACT" in
            "critical")
                alert_slack "${CLAUDE_AGENT_ID:-unknown}" \
                    "Critical Error: $ERROR_TYPE - ${ERROR_MSG:0:100}"
                ;;
            "high")
                notify_slack "error.high" "${CLAUDE_AGENT_ID:-unknown}" \
                    "$ERROR_TYPE: ${ERROR_MSG:0:100}" "high"
                ;;
            *)
                notify_slack "error.$ERROR_TYPE" "${CLAUDE_AGENT_ID:-unknown}" \
                    "${ERROR_MSG:0:100}" "$IMPACT"
                ;;
        esac
        
        # Notify about missing capabilities
        if [ -n "$missing_resource" ] && [ "$strategy" = "install_tool" -o "$strategy" = "install_dependency" ]; then
            notify_slack "capability.missing" "${CLAUDE_AGENT_ID:-unknown}" \
                "Missing: $missing_resource (Strategy: $strategy)" "high"
        fi
        
        # Update session error count
        sqlite3 "$MEMORY_DB" "
            UPDATE hook_agent_sessions 
            SET total_errors = total_errors + 1
            WHERE session_id = '$SESSION_ID' 
              AND agent_id = '${CLAUDE_AGENT_ID:-unknown}'
        "
        ;;
        
    "error.recovered")
        # Log successful recovery
        sqlite3 "$MEMORY_DB" << EOF
UPDATE hook_error_events 
SET error_context = json_set(error_context,
    '$.recovered', 1,
    '$.recovery_time', '$(date -u +"%Y-%m-%d %H:%M:%S")'
)
WHERE agent_id = '${CLAUDE_AGENT_ID:-unknown}'
  AND recovery_attempted = 1
  AND json_extract(error_context, '$.recovered') IS NULL
ORDER BY timestamp DESC
LIMIT 1;
EOF
        
        echo "[$TIMESTAMP] RECOVERED: Agent=${CLAUDE_AGENT_ID:-unknown}" >> "$ERROR_LOG"
        
        # Notify about successful recovery
        notify_slack "error.recovered" "${CLAUDE_AGENT_ID:-unknown}" \
            "Successfully recovered from error" "low"
        ;;
        
    "test")
        # Test mode
        echo "Error recovery hook is working!"
        echo "Would log to: $MEMORY_DB"
        echo "Error log: $ERROR_LOG"
        echo "Testing recovery strategy detection:"
        echo "  'permission denied' -> $(get_recovery_strategy 'permission denied' 'file_error')"
        echo "  'command not found: git' -> $(get_recovery_strategy 'command not found: git' 'bash_error')"
        if is_slack_enabled; then
            echo "Slack notifications: ENABLED"
        else
            echo "Slack notifications: DISABLED"
        fi
        ;;
esac