# Claude Code Hooks for Agent Tracking

## Overview

Claude Code hooks allow us to intercept and track all agent activities, providing comprehensive monitoring of progress, failures, and successes. All data is stored in SQLite with file backups for visibility.

## Available Hooks

Claude Code supports these hooks that we can leverage:

1. **Tool Hooks** - Intercept all tool usage
2. **Message Hooks** - Track agent communications
3. **Error Hooks** - Capture failures and errors
4. **Completion Hooks** - Track task completions
5. **Custom Hooks** - Agent-specific tracking

## Hook Implementation Strategy

### 1. Tool Usage Tracking

Every time an agent uses a tool (Read, Write, Bash, Task, etc.), we capture:
- Which agent used the tool
- Tool parameters
- Success/failure
- Execution time
- Result summary

### 2. Progress Monitoring

Track agent progress through:
- Task status changes
- Milestone completions
- Work session tracking
- Time spent per task

### 3. Error and Failure Tracking

Comprehensive error capture:
- Tool failures
- Task blockages
- Missing capabilities
- Recovery attempts

### 4. Success Metrics

Track agent achievements:
- Completed deliverables
- Quality scores
- Performance metrics
- Collaboration success

## Hook Configuration

### Main Hook Configuration File

```json
{
  "hooks": {
    "enabled": true,
    "storage": {
      "primary": "sqlite",
      "backup": "files",
      "sync_interval": 60
    },
    "tracking": {
      "tool_usage": true,
      "progress_updates": true,
      "error_capture": true,
      "performance_metrics": true,
      "agent_communications": true
    },
    "filters": {
      "exclude_tools": [],
      "exclude_agents": [],
      "sensitive_data_masking": true
    }
  }
}
```

## SQLite Schema for Hook Data

```sql
-- Tool usage tracking via hooks
CREATE TABLE IF NOT EXISTS hook_tool_usage (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    tool_parameters TEXT, -- JSON, with sensitive data masked
    execution_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_end TIMESTAMP,
    execution_duration_ms INTEGER,
    success BOOLEAN,
    error_message TEXT,
    result_summary TEXT, -- Brief summary, not full result
    task_context TEXT, -- Current task ID if applicable
    session_id TEXT,
    hook_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Progress tracking via hooks
CREATE TABLE IF NOT EXISTS hook_progress_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    event_type TEXT, -- 'task_start', 'milestone', 'task_complete', etc.
    task_id TEXT,
    progress_percentage INTEGER,
    milestone_name TEXT,
    milestone_details TEXT, -- JSON
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Error tracking via hooks
CREATE TABLE IF NOT EXISTS hook_error_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    error_type TEXT, -- 'tool_failure', 'task_blocked', 'capability_missing', etc.
    error_message TEXT,
    error_context TEXT, -- JSON with full context
    stack_trace TEXT,
    recovery_attempted BOOLEAN DEFAULT FALSE,
    recovery_successful BOOLEAN,
    impact_level TEXT, -- 'low', 'medium', 'high', 'critical'
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Success tracking via hooks
CREATE TABLE IF NOT EXISTS hook_success_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    success_type TEXT, -- 'deliverable_created', 'test_passed', 'milestone_achieved'
    deliverable_name TEXT,
    quality_score REAL, -- 0.0 to 1.0
    performance_metrics TEXT, -- JSON metrics
    impact_assessment TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Agent communication tracking
CREATE TABLE IF NOT EXISTS hook_agent_communications (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_agent TEXT NOT NULL,
    to_agent TEXT,
    communication_type TEXT, -- 'delegation', 'query', 'response', 'discovery_share'
    message_summary TEXT,
    full_message TEXT, -- Stored but not synced to files
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT,
    FOREIGN KEY (from_agent) REFERENCES agent_registry(agent_id)
);

-- Session tracking
CREATE TABLE IF NOT EXISTS hook_agent_sessions (
    session_id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    total_tools_used INTEGER DEFAULT 0,
    total_errors INTEGER DEFAULT 0,
    total_successes INTEGER DEFAULT 0,
    session_metadata TEXT, -- JSON
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Indexes for performance
CREATE INDEX idx_hook_tool_usage_agent ON hook_tool_usage(agent_id, execution_start);
CREATE INDEX idx_hook_progress_agent ON hook_progress_events(agent_id, timestamp);
CREATE INDEX idx_hook_errors_agent ON hook_error_events(agent_id, error_type);
CREATE INDEX idx_hook_success_agent ON hook_success_events(agent_id, success_type);
```

## Hook Implementation Files

### 1. Tool Usage Hook Script

Save as `.claude/hooks/tool-usage-hook.sh`:

```bash
#!/bin/bash
# Tool usage tracking hook for Claude Code

# Environment variables provided by Claude Code:
# CLAUDE_AGENT_ID - Current agent identifier
# CLAUDE_TOOL_NAME - Tool being used
# CLAUDE_TOOL_PARAMS - Tool parameters (JSON)
# CLAUDE_TASK_ID - Current task ID if any

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
SESSION_ID=${CLAUDE_SESSION_ID:-"default"}

# Function to log to SQLite
log_tool_usage() {
    local start_time="$1"
    local success="$2"
    local error_msg="$3"
    local result_summary="$4"
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    # Mask sensitive data in parameters
    SAFE_PARAMS=$(echo "$CLAUDE_TOOL_PARAMS" | sed 's/"password":"[^"]*"/"password":"***"/g')
    
    sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_tool_usage (
    agent_id, tool_name, tool_parameters, 
    execution_start, execution_end, execution_duration_ms,
    success, error_message, result_summary,
    task_context, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', '$CLAUDE_TOOL_NAME', '$SAFE_PARAMS',
    datetime('$TIMESTAMP'), datetime('now'), $duration,
    $success, '$error_msg', '$result_summary',
    '$CLAUDE_TASK_ID', '$SESSION_ID'
);
EOF
}

# Main hook logic
case "$CLAUDE_HOOK_EVENT" in
    "tool.before")
        # Record tool start
        echo "$TIMESTAMP|TOOL_START|$CLAUDE_AGENT_ID|$CLAUDE_TOOL_NAME" >> /tmp/claude-hooks.log
        echo $(date +%s%3N) > /tmp/tool-start-$$.time
        ;;
        
    "tool.after")
        # Record tool completion
        START_TIME=$(cat /tmp/tool-start-$$.time 2>/dev/null || echo $(date +%s%3N))
        rm -f /tmp/tool-start-$$.time
        
        # Extract result summary (first 200 chars)
        RESULT_SUMMARY=$(echo "$CLAUDE_TOOL_RESULT" | head -c 200 | tr '\n' ' ')
        
        log_tool_usage "$START_TIME" "1" "" "$RESULT_SUMMARY"
        ;;
        
    "tool.error")
        # Record tool failure
        START_TIME=$(cat /tmp/tool-start-$$.time 2>/dev/null || echo $(date +%s%3N))
        rm -f /tmp/tool-start-$$.time
        
        ERROR_MSG=$(echo "$CLAUDE_ERROR_MESSAGE" | tr '\n' ' ' | tr "'" '"')
        log_tool_usage "$START_TIME" "0" "$ERROR_MSG" ""
        
        # Also log to error events
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_error_events (
    agent_id, error_type, error_message, error_context,
    impact_level, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', 'tool_failure', '$ERROR_MSG',
    '{"tool": "$CLAUDE_TOOL_NAME", "params": $SAFE_PARAMS}',
    'medium', '$SESSION_ID'
);
EOF
        ;;
esac
```

### 2. Progress Tracking Hook

Save as `.claude/hooks/progress-hook.sh`:

```bash
#!/bin/bash
# Progress tracking hook for Claude Code

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
BACKUP_DIR="$HOME/.claude/agent-progress-backup"
mkdir -p "$BACKUP_DIR"

# Function to sync progress to file
sync_progress_to_file() {
    local agent_id="$1"
    local progress_file="$BACKUP_DIR/Agent-${agent_id}-progress.log"
    
    # Append progress event to file
    echo "[$TIMESTAMP] $CLAUDE_PROGRESS_EVENT: $CLAUDE_PROGRESS_DETAILS" >> "$progress_file"
    
    # Keep file size manageable (last 1000 lines)
    tail -n 1000 "$progress_file" > "$progress_file.tmp" && mv "$progress_file.tmp" "$progress_file"
}

# Log progress event
case "$CLAUDE_PROGRESS_EVENT" in
    "task.start")
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_progress_events (
    agent_id, event_type, task_id, progress_percentage,
    milestone_name, milestone_details, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', 'task_start', '$CLAUDE_TASK_ID', 0,
    'Task Started', '{"task_title": "$CLAUDE_TASK_TITLE"}',
    '$CLAUDE_SESSION_ID'
);
EOF
        sync_progress_to_file "$CLAUDE_AGENT_ID"
        ;;
        
    "milestone.reached")
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_progress_events (
    agent_id, event_type, task_id, progress_percentage,
    milestone_name, milestone_details, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', 'milestone', '$CLAUDE_TASK_ID', 
    ${CLAUDE_PROGRESS_PERCENTAGE:-50},
    '$CLAUDE_MILESTONE_NAME', '$CLAUDE_MILESTONE_DETAILS',
    '$CLAUDE_SESSION_ID'
);
EOF
        sync_progress_to_file "$CLAUDE_AGENT_ID"
        ;;
        
    "task.complete")
        sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_progress_events (
    agent_id, event_type, task_id, progress_percentage,
    milestone_name, milestone_details, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', 'task_complete', '$CLAUDE_TASK_ID', 100,
    'Task Completed', '{"deliverables": $CLAUDE_DELIVERABLES}',
    '$CLAUDE_SESSION_ID'
);

-- Also record success
INSERT INTO hook_success_events (
    agent_id, success_type, deliverable_name,
    quality_score, performance_metrics, session_id
) VALUES (
    '$CLAUDE_AGENT_ID', 'task_completed', '$CLAUDE_TASK_ID',
    ${CLAUDE_QUALITY_SCORE:-0.8}, '$CLAUDE_PERFORMANCE_METRICS',
    '$CLAUDE_SESSION_ID'
);
EOF
        sync_progress_to_file "$CLAUDE_AGENT_ID"
        ;;
esac
```

### 3. Error Recovery Hook

Save as `.claude/hooks/error-recovery-hook.sh`:

```bash
#!/bin/bash
# Error recovery tracking hook

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

# Check if this is a recoverable error
is_recoverable() {
    case "$1" in
        *"permission denied"*) echo "retry_with_sudo" ;;
        *"command not found"*) echo "install_tool" ;;
        *"no such file"*) echo "create_file" ;;
        *"connection refused"*) echo "retry_later" ;;
        *) echo "unknown" ;;
    esac
}

# Attempt recovery
attempt_recovery() {
    local error_type="$1"
    local recovery_method=$(is_recoverable "$CLAUDE_ERROR_MESSAGE")
    
    if [ "$recovery_method" != "unknown" ]; then
        # Log recovery attempt
        sqlite3 "$MEMORY_DB" << EOF
UPDATE hook_error_events 
SET recovery_attempted = 1,
    recovery_method = '$recovery_method'
WHERE event_id = (
    SELECT event_id FROM hook_error_events 
    WHERE agent_id = '$CLAUDE_AGENT_ID' 
    ORDER BY timestamp DESC LIMIT 1
);
EOF
        
        # Trigger recovery action
        case "$recovery_method" in
            "retry_with_sudo")
                echo "SUGGEST: Request elevated permissions"
                ;;
            "install_tool")
                # Record missing tool
                TOOL_NAME=$(echo "$CLAUDE_ERROR_MESSAGE" | grep -oP "command not found: \K\w+")
                sqlite3 "$MEMORY_DB" << EOF
INSERT INTO missing_capabilities (
    capability_type, capability_name, requested_by_agent,
    task_context, impact_level
) VALUES (
    'tool', '$TOOL_NAME', '$CLAUDE_AGENT_ID',
    '{"error": "$CLAUDE_ERROR_MESSAGE"}', 'high'
);
EOF
                ;;
        esac
    fi
}

# Main error handling
if [ "$CLAUDE_HOOK_EVENT" = "error.captured" ]; then
    attempt_recovery "$CLAUDE_ERROR_TYPE"
fi
```

### 4. Communication Tracking Hook

Save as `.claude/hooks/communication-hook.sh`:

```bash
#!/bin/bash
# Track agent-to-agent communications

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

# Log agent communications
if [ "$CLAUDE_HOOK_EVENT" = "agent.communicate" ]; then
    sqlite3 "$MEMORY_DB" << EOF
INSERT INTO hook_agent_communications (
    from_agent, to_agent, communication_type,
    message_summary, full_message, session_id
) VALUES (
    '$CLAUDE_FROM_AGENT', '$CLAUDE_TO_AGENT', '$CLAUDE_COMM_TYPE',
    '${CLAUDE_MESSAGE_SUMMARY:-Communication}', '$CLAUDE_MESSAGE',
    '$CLAUDE_SESSION_ID'
);
EOF
fi
```

### 5. Master Hook Configuration

Save as `.claude/hooks/config.json`:

```json
{
  "hooks": [
    {
      "name": "tool-usage-tracking",
      "script": "tool-usage-hook.sh",
      "events": ["tool.before", "tool.after", "tool.error"],
      "enabled": true
    },
    {
      "name": "progress-tracking",
      "script": "progress-hook.sh",
      "events": ["task.start", "milestone.reached", "task.complete"],
      "enabled": true
    },
    {
      "name": "error-recovery",
      "script": "error-recovery-hook.sh",
      "events": ["error.captured", "error.recovered"],
      "enabled": true
    },
    {
      "name": "communication-tracking",
      "script": "communication-hook.sh",
      "events": ["agent.communicate", "agent.delegate"],
      "enabled": true
    },
    {
      "name": "session-tracking",
      "script": "session-hook.sh",
      "events": ["session.start", "session.end"],
      "enabled": true
    }
  ],
  "global_settings": {
    "log_level": "info",
    "batch_interval": 60,
    "max_retries": 3,
    "storage_backend": "sqlite",
    "backup_to_files": true
  }
}
```

## Analytics Queries

### Agent Performance Dashboard

```sql
-- Real-time agent performance
CREATE VIEW agent_performance_dashboard AS
SELECT 
    a.agent_id,
    a.name as agent_name,
    COUNT(DISTINCT ht.event_id) as total_tool_uses,
    AVG(CASE WHEN ht.success THEN 1 ELSE 0 END) as tool_success_rate,
    AVG(ht.execution_duration_ms) as avg_tool_duration_ms,
    COUNT(DISTINCT he.event_id) as total_errors,
    COUNT(DISTINCT hs.event_id) as total_successes,
    COUNT(DISTINCT hp.task_id) as tasks_worked_on,
    MAX(ht.hook_timestamp) as last_activity
FROM agent_registry a
LEFT JOIN hook_tool_usage ht ON a.agent_id = ht.agent_id
LEFT JOIN hook_error_events he ON a.agent_id = he.agent_id
LEFT JOIN hook_success_events hs ON a.agent_id = hs.agent_id
LEFT JOIN hook_progress_events hp ON a.agent_id = hp.agent_id
GROUP BY a.agent_id, a.name;

-- Most problematic tools
CREATE VIEW problematic_tools AS
SELECT 
    tool_name,
    COUNT(*) as total_uses,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failures,
    AVG(CASE WHEN success THEN 1 ELSE 0 END) as success_rate,
    GROUP_CONCAT(DISTINCT error_message) as common_errors
FROM hook_tool_usage
GROUP BY tool_name
HAVING success_rate < 0.9
ORDER BY failures DESC;

-- Agent collaboration patterns
CREATE VIEW collaboration_patterns AS
SELECT 
    from_agent,
    to_agent,
    communication_type,
    COUNT(*) as interaction_count,
    DATE(timestamp) as interaction_date
FROM hook_agent_communications
GROUP BY from_agent, to_agent, communication_type, DATE(timestamp)
ORDER BY interaction_date DESC, interaction_count DESC;
```

## File Backup System

```bash
#!/bin/bash
# Backup hook data to files (run periodically)

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
BACKUP_DIR="$HOME/.claude/agent-tracking-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR/daily"

# Export hook data to CSV files
sqlite3 -header -csv "$MEMORY_DB" "SELECT * FROM hook_tool_usage WHERE DATE(hook_timestamp) = DATE('now')" > "$BACKUP_DIR/daily/tool_usage_$TIMESTAMP.csv"

sqlite3 -header -csv "$MEMORY_DB" "SELECT * FROM hook_progress_events WHERE DATE(timestamp) = DATE('now')" > "$BACKUP_DIR/daily/progress_$TIMESTAMP.csv"

sqlite3 -header -csv "$MEMORY_DB" "SELECT * FROM hook_error_events WHERE DATE(timestamp) = DATE('now')" > "$BACKUP_DIR/daily/errors_$TIMESTAMP.csv"

sqlite3 -header -csv "$MEMORY_DB" "SELECT * FROM hook_success_events WHERE DATE(timestamp) = DATE('now')" > "$BACKUP_DIR/daily/successes_$TIMESTAMP.csv"

# Create daily summary
sqlite3 -header -csv "$MEMORY_DB" "SELECT * FROM agent_performance_dashboard" > "$BACKUP_DIR/daily/performance_summary_$TIMESTAMP.csv"

# Compress old backups
find "$BACKUP_DIR/daily" -name "*.csv" -mtime +7 -exec gzip {} \;
```

## Benefits

1. **Complete Visibility**: Every agent action tracked
2. **Real-time Monitoring**: Live performance dashboards
3. **Error Pattern Detection**: Identify recurring issues
4. **Performance Optimization**: Find slow operations
5. **Audit Trail**: Complete history of all activities
6. **Automated Recovery**: Self-healing capabilities
7. **Backup Safety**: Files mirror SQLite data