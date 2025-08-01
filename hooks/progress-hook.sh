#!/bin/bash
# Progress tracking hook for Claude Code
# Monitors agent progress, milestones, and task completions

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
BACKUP_DIR="$HOME/.claude/agent-progress-backup"
SESSION_ID=${CLAUDE_SESSION_ID:-"default"}

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Source Slack integration
source "$(dirname "$0")/slack-integration.sh" 2>/dev/null || true

# Function to sync progress to file
sync_progress_to_file() {
    local agent_id="$1"
    local event_type="$2"
    local details="$3"
    local progress_file="$BACKUP_DIR/Agent-${agent_id}-progress.log"
    
    # Create formatted log entry
    local log_entry="[$TIMESTAMP] $event_type"
    [ -n "$CLAUDE_TASK_ID" ] && log_entry="$log_entry Task:$CLAUDE_TASK_ID"
    [ -n "$details" ] && log_entry="$log_entry - $details"
    
    # Append to file
    echo "$log_entry" >> "$progress_file"
    
    # Keep file size manageable (last 1000 lines)
    if [ $(wc -l < "$progress_file" 2>/dev/null || echo 0) -gt 1000 ]; then
        tail -n 1000 "$progress_file" > "$progress_file.tmp" && mv "$progress_file.tmp" "$progress_file"
    fi
}

# Function to calculate task duration
get_task_duration() {
    local task_id="$1"
    local duration=$(sqlite3 "$MEMORY_DB" "
        SELECT CAST((julianday('now') - julianday(MIN(timestamp))) * 24 * 60 AS INTEGER)
        FROM hook_progress_events 
        WHERE task_id = '$task_id' AND event_type = 'task_start'
    " 2>/dev/null || echo "0")
    echo "$duration"
}

# Escape SQL strings
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

# Log progress event
log_progress_event() {
    local event_type="$1"
    local progress="$2"
    local milestone_name="$3"
    local milestone_details="$4"
    
    sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_progress_events (
    agent_id, event_type, task_id, progress_percentage,
    milestone_name, milestone_details, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    '$event_type', 
    '${CLAUDE_TASK_ID:-}', 
    ${progress:-0},
    '$(escape_sql "$milestone_name")', 
    '$(escape_sql "$milestone_details")',
    '$SESSION_ID'
);
EOF
}

# Main progress tracking logic
case "${1:-$CLAUDE_PROGRESS_EVENT}" in
    "task.start")
        TASK_TITLE=$(escape_sql "${CLAUDE_TASK_TITLE:-New Task}")
        
        log_progress_event "task_start" "0" "Task Started" "{\"task_title\": \"$TASK_TITLE\"}"
        sync_progress_to_file "${CLAUDE_AGENT_ID:-unknown}" "TASK_START" "$TASK_TITLE"
        
        # Initialize task in main task table if not exists
        sqlite3 "$MEMORY_DB" << EOF
INSERT OR IGNORE INTO agent_tasks (
    task_id, agent_id, task_date, sequence_number,
    status, title, created_at
) VALUES (
    '${CLAUDE_TASK_ID:-}', 
    '${CLAUDE_AGENT_ID:-unknown}',
    date('now'), 
    1,
    'in_progress', 
    '$TASK_TITLE',
    datetime('now')
);

UPDATE agent_tasks 
SET status = 'in_progress', started_at = datetime('now')
WHERE task_id = '${CLAUDE_TASK_ID:-}';
EOF
        ;;
        
    "milestone.reached")
        MILESTONE_NAME=$(escape_sql "${CLAUDE_MILESTONE_NAME:-Milestone}")
        MILESTONE_DETAILS=$(escape_sql "${CLAUDE_MILESTONE_DETAILS:-{}}")
        PROGRESS=${CLAUDE_PROGRESS_PERCENTAGE:-50}
        
        log_progress_event "milestone" "$PROGRESS" "$MILESTONE_NAME" "$MILESTONE_DETAILS"
        sync_progress_to_file "${CLAUDE_AGENT_ID:-unknown}" "MILESTONE" "$MILESTONE_NAME ($PROGRESS%)"
        
        # Notify Slack about milestones
        notify_slack "milestone.reached" "${CLAUDE_AGENT_ID:-unknown}" \
            "$MILESTONE_NAME ($PROGRESS%)" "medium"
        ;;
        
    "deliverable.created")
        DELIVERABLE_NAME=$(escape_sql "${CLAUDE_DELIVERABLE_NAME:-Deliverable}")
        DELIVERABLE_PATH=$(escape_sql "${CLAUDE_DELIVERABLE_PATH:-}")
        
        log_progress_event "deliverable" "70" "Deliverable Created" \
            "{\"name\": \"$DELIVERABLE_NAME\", \"path\": \"$DELIVERABLE_PATH\"}"
        sync_progress_to_file "${CLAUDE_AGENT_ID:-unknown}" "DELIVERABLE" "$DELIVERABLE_NAME"
        
        # Notify Slack about deliverable
        notify_slack "deliverable.created" "${CLAUDE_AGENT_ID:-unknown}" \
            "$DELIVERABLE_NAME" "medium"
        
        # Record success event
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_success_events (
    agent_id, success_type, deliverable_name,
    quality_score, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    'deliverable_created', 
    '$DELIVERABLE_NAME',
    0.8,
    '$SESSION_ID'
);
EOF
        ;;
        
    "task.complete")
        DELIVERABLES=$(escape_sql "${CLAUDE_DELIVERABLES:-[]}")
        DURATION=$(get_task_duration "${CLAUDE_TASK_ID:-}")
        QUALITY_SCORE=${CLAUDE_QUALITY_SCORE:-0.8}
        
        log_progress_event "task_complete" "100" "Task Completed" \
            "{\"deliverables\": $DELIVERABLES, \"duration_minutes\": $DURATION}"
        sync_progress_to_file "${CLAUDE_AGENT_ID:-unknown}" "TASK_COMPLETE" "Duration: ${DURATION}min"
        
        # Notify Slack about task completion
        notify_slack "task.complete" "${CLAUDE_AGENT_ID:-unknown}" \
            "Task ${CLAUDE_TASK_ID:-} completed - duration:$DURATION" "important"
        
        # Update task status
        sqlite3 "$MEMORY_DB" << EOF
UPDATE agent_tasks 
SET status = 'completed', 
    completed_at = datetime('now')
WHERE task_id = '${CLAUDE_TASK_ID:-}';

-- Record success
INSERT INTO hook_success_events (
    agent_id, success_type, deliverable_name,
    quality_score, performance_metrics, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    'task_completed', 
    '${CLAUDE_TASK_ID:-}',
    $QUALITY_SCORE, 
    '{"duration_minutes": $DURATION, "deliverables_count": $(echo "$DELIVERABLES" | grep -o "," | wc -l || echo 1)}',
    '$SESSION_ID'
);

-- Update session stats
UPDATE hook_agent_sessions 
SET total_successes = total_successes + 1
WHERE session_id = '$SESSION_ID' 
  AND agent_id = '${CLAUDE_AGENT_ID:-unknown}';
EOF
        ;;
        
    "task.blocked")
        BLOCKER=$(escape_sql "${CLAUDE_BLOCKER_REASON:-Unknown}")
        BLOCKER_TYPE="${CLAUDE_BLOCKER_TYPE:-missing_capability}"
        
        log_progress_event "task_blocked" "${CLAUDE_PROGRESS_PERCENTAGE:-0}" \
            "Task Blocked" "{\"reason\": \"$BLOCKER\", \"type\": \"$BLOCKER_TYPE\"}"
        sync_progress_to_file "${CLAUDE_AGENT_ID:-unknown}" "TASK_BLOCKED" "$BLOCKER"
        
        # Notify Slack about blocked task
        notify_slack "task.blocked" "${CLAUDE_AGENT_ID:-unknown}" \
            "$BLOCKER" "high"
        
        # Update task status
        sqlite3 "$MEMORY_DB" << EOF
UPDATE agent_tasks 
SET status = 'blocked'
WHERE task_id = '${CLAUDE_TASK_ID:-}';

-- Log as error event
INSERT INTO hook_error_events (
    agent_id, error_type, error_message, error_context,
    impact_level, session_id
) VALUES (
    '${CLAUDE_AGENT_ID:-unknown}', 
    'task_blocked',
    '$BLOCKER',
    '{"task_id": "${CLAUDE_TASK_ID:-}", "blocker_type": "$BLOCKER_TYPE"}',
    'high',
    '$SESSION_ID'
);
EOF
        ;;
        
    "test")
        # Test mode
        echo "Progress hook is working!"
        echo "Would log to: $MEMORY_DB"
        echo "Backup directory: $BACKUP_DIR"
        ;;
esac