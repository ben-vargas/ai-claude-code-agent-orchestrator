#!/bin/bash
# Slack notification handler for Claude Code hooks
# Sends agent activity updates to Slack channels

# Load configuration
CONFIG_FILE="$HOME/.claude/hooks/slack-config.json"
QUEUE_FILE="$HOME/.claude/hooks/slack-queue.json"
MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

# Default values
SLACK_WEBHOOK_URL=""
SLACK_CHANNEL=""
NOTIFICATION_LEVEL="important" # all, important, errors_only
BATCH_INTERVAL=30 # seconds
RATE_LIMIT=10 # max messages per minute

# Colors for Slack (using emoji)
SUCCESS_EMOJI="✅"
ERROR_EMOJI="❌"
WARNING_EMOJI="⚠️"
INFO_EMOJI="ℹ️"
PROGRESS_EMOJI="📊"
TOOL_EMOJI="🛠️"
MILESTONE_EMOJI="🎯"
BLOCKED_EMOJI="🚫"

# Load Slack configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        SLACK_WEBHOOK_URL=$(jq -r '.webhook_url // ""' "$CONFIG_FILE")
        SLACK_CHANNEL=$(jq -r '.channel // ""' "$CONFIG_FILE")
        NOTIFICATION_LEVEL=$(jq -r '.notification_level // "important"' "$CONFIG_FILE")
        BATCH_INTERVAL=$(jq -r '.batch_interval // 30' "$CONFIG_FILE")
        RATE_LIMIT=$(jq -r '.rate_limit // 10' "$CONFIG_FILE")
    fi
}

# Check if Slack is configured
is_slack_configured() {
    [ -n "$SLACK_WEBHOOK_URL" ] && [ "$SLACK_WEBHOOK_URL" != "null" ]
}

# Format duration for Slack
format_duration() {
    local ms=$1
    if [ $ms -lt 1000 ]; then
        echo "${ms}ms"
    elif [ $ms -lt 60000 ]; then
        echo "$((ms/1000))s"
    else
        echo "$((ms/60000))m $((ms%60000/1000))s"
    fi
}

# Escape text for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g'
}

# Send message to Slack
send_to_slack() {
    local payload="$1"
    
    if ! is_slack_configured; then
        return 1
    fi
    
    # Send to Slack
    curl -X POST \
        -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK_URL" \
        -s -o /dev/null
}

# Queue message for batching
queue_message() {
    local message="$1"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
    
    # Initialize queue file if doesn't exist
    if [ ! -f "$QUEUE_FILE" ]; then
        echo '{"messages": []}' > "$QUEUE_FILE"
    fi
    
    # Add message to queue
    jq --arg msg "$message" --arg ts "$timestamp" \
        '.messages += [{"timestamp": $ts, "message": $msg}]' \
        "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
}

# Process message queue
process_queue() {
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
        return
    fi
    
    local message_count=$(jq '.messages | length' "$QUEUE_FILE")
    if [ "$message_count" -eq 0 ]; then
        return
    fi
    
    # Build consolidated message
    local blocks='[{"type": "header", "text": {"type": "plain_text", "text": "🤖 Agent Activity Summary"}},'
    
    # Group messages by type
    local messages=$(jq -r '.messages[].message' "$QUEUE_FILE" | sort | uniq -c | sort -rn)
    
    blocks+="{\"type\": \"section\", \"text\": {\"type\": \"mrkdwn\", \"text\": \""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            count=$(echo "$line" | awk '{print $1}')
            msg=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
            if [ $count -gt 1 ]; then
                blocks+="$msg (×$count)\n"
            else
                blocks+="$msg\n"
            fi
        fi
    done <<< "$messages"
    blocks+="\"}},"
    
    # Add timestamp
    blocks+="{\"type\": \"context\", \"elements\": [{\"type\": \"mrkdwn\", \"text\": \"_$(date '+%Y-%m-%d %H:%M:%S')_\"}]}]"
    
    # Send consolidated message
    local payload="{\"blocks\": $blocks}"
    send_to_slack "$payload"
    
    # Clear queue
    echo '{"messages": []}' > "$QUEUE_FILE"
}

# Create Slack notification based on event type
create_notification() {
    local event_type="$1"
    local agent_id="${2:-unknown}"
    local details="$3"
    
    case "$event_type" in
        "task.start")
            echo "$PROGRESS_EMOJI *${agent_id}* started task: $details"
            ;;
            
        "task.complete")
            local duration=$(echo "$details" | grep -oE 'duration:[0-9]+' | cut -d: -f2)
            if [ -n "$duration" ]; then
                echo "$SUCCESS_EMOJI *${agent_id}* completed task ($(format_duration $duration))"
            else
                echo "$SUCCESS_EMOJI *${agent_id}* completed task"
            fi
            ;;
            
        "task.blocked")
            echo "$BLOCKED_EMOJI *${agent_id}* blocked: $details"
            ;;
            
        "milestone.reached")
            echo "$MILESTONE_EMOJI *${agent_id}* reached milestone: $details"
            ;;
            
        "tool.error")
            echo "$ERROR_EMOJI *${agent_id}* tool error: $details"
            ;;
            
        "error.critical")
            echo "$ERROR_EMOJI *CRITICAL ERROR* - ${agent_id}: $details"
            ;;
            
        "capability.missing")
            echo "$WARNING_EMOJI *${agent_id}* missing capability: $details"
            ;;
            
        "deliverable.created")
            echo "$SUCCESS_EMOJI *${agent_id}* created deliverable: $details"
            ;;
            
        "performance.alert")
            echo "$WARNING_EMOJI *Performance Alert* - ${agent_id}: $details"
            ;;
            
        *)
            echo "$INFO_EMOJI *${agent_id}* - $event_type: $details"
            ;;
    esac
}

# Check if notification should be sent based on level
should_notify() {
    local event_type="$1"
    local impact="${2:-medium}"
    
    case "$NOTIFICATION_LEVEL" in
        "all")
            return 0
            ;;
        "important")
            case "$event_type" in
                "task.complete"|"task.blocked"|"error."*|"capability.missing"|"milestone.reached")
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        "errors_only")
            case "$event_type" in
                "error."*|"task.blocked"|"capability.missing")
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
    esac
}

# Send immediate alert for critical events
send_immediate_alert() {
    local title="$1"
    local message="$2"
    local color="$3"
    
    local payload=$(cat << EOF
{
    "attachments": [{
        "color": "$color",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "$title"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "$message"
                }
            },
            {
                "type": "context",
                "elements": [{
                    "type": "mrkdwn",
                    "text": "_$(date '+%Y-%m-%d %H:%M:%S')_"
                }]
            }
        ]
    }]
}
EOF
)
    
    send_to_slack "$payload"
}

# Monitor performance and send alerts
check_performance_alerts() {
    # Check for high error rates
    local error_rate=$(sqlite3 "$MEMORY_DB" "
        SELECT ROUND(100.0 * SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) / COUNT(*), 1)
        FROM hook_tool_usage
        WHERE datetime(hook_timestamp) > datetime('now', '-5 minutes')
    " 2>/dev/null || echo "0")
    
    if (( $(echo "$error_rate > 20" | bc -l) )); then
        send_immediate_alert "⚠️ High Error Rate Alert" \
            "Error rate is at ${error_rate}% in the last 5 minutes" \
            "warning"
    fi
    
    # Check for stuck tasks
    local stuck_tasks=$(sqlite3 "$MEMORY_DB" "
        SELECT agent_id, task_id, 
               CAST((julianday('now') - julianday(MIN(timestamp))) * 24 AS INTEGER) as hours
        FROM hook_progress_events
        WHERE event_type = 'task_start'
          AND task_id NOT IN (
              SELECT task_id FROM hook_progress_events 
              WHERE event_type = 'task_complete'
          )
          AND datetime(timestamp) < datetime('now', '-2 hours')
        GROUP BY agent_id, task_id
    " 2>/dev/null)
    
    if [ -n "$stuck_tasks" ]; then
        send_immediate_alert "⏰ Stuck Tasks Alert" \
            "Tasks running for over 2 hours:\n$stuck_tasks" \
            "warning"
    fi
}

# Generate daily summary
generate_daily_summary() {
    local summary=$(sqlite3 -separator ' | ' "$MEMORY_DB" << 'EOF'
SELECT 
    'Total Agents: ' || COUNT(DISTINCT agent_id) || '\n' ||
    'Total Operations: ' || COUNT(*) || '\n' ||
    'Success Rate: ' || ROUND(100.0 * SUM(CASE WHEN success THEN 1 ELSE 0 END) / COUNT(*), 1) || '%\n' ||
    'Avg Duration: ' || ROUND(AVG(execution_duration_ms)/1000.0, 1) || 's'
FROM hook_tool_usage
WHERE date(hook_timestamp) = date('now');
EOF
)
    
    local top_agents=$(sqlite3 -separator '\n' "$MEMORY_DB" << 'EOF'
SELECT '• ' || agent_id || ': ' || COUNT(*) || ' operations'
FROM hook_tool_usage
WHERE date(hook_timestamp) = date('now')
GROUP BY agent_id
ORDER BY COUNT(*) DESC
LIMIT 5;
EOF
)
    
    send_immediate_alert "📊 Daily Agent Summary" \
        "*Overview:*\n$summary\n\n*Top Agents:*\n$top_agents" \
        "good"
}

# Main notification handler
handle_notification() {
    local event_type="$1"
    local agent_id="$2"
    local details="$3"
    local impact="${4:-medium}"
    
    # Load configuration
    load_config
    
    # Check if we should notify
    if ! should_notify "$event_type" "$impact"; then
        return
    fi
    
    # Create notification message
    local message=$(create_notification "$event_type" "$agent_id" "$details")
    
    # Queue or send based on impact
    if [ "$impact" = "critical" ] || [[ "$event_type" == "error.critical" ]]; then
        send_immediate_alert "🚨 Critical Alert" "$message" "danger"
    else
        queue_message "$message"
    fi
}

# Process command line arguments
case "${1:-notify}" in
    "notify")
        # Called by hooks to send notification
        handle_notification "$2" "$3" "$4" "$5"
        ;;
        
    "process")
        # Process queued messages
        load_config
        process_queue
        ;;
        
    "configure")
        # Interactive configuration
        echo "Slack Notification Configuration"
        echo "==============================="
        echo ""
        read -p "Slack Webhook URL: " webhook
        read -p "Channel (optional): " channel
        echo "Notification Level:"
        echo "  1) All events"
        echo "  2) Important only (default)"
        echo "  3) Errors only"
        read -p "Choice [2]: " level_choice
        
        case "$level_choice" in
            1) level="all" ;;
            3) level="errors_only" ;;
            *) level="important" ;;
        esac
        
        # Save configuration
        cat > "$CONFIG_FILE" << EOF
{
    "webhook_url": "$webhook",
    "channel": "$channel",
    "notification_level": "$level",
    "batch_interval": 30,
    "rate_limit": 10
}
EOF
        chmod 600 "$CONFIG_FILE"
        echo "Configuration saved to $CONFIG_FILE"
        ;;
        
    "test")
        # Test Slack connection
        load_config
        if is_slack_configured; then
            send_immediate_alert "🧪 Test Message" \
                "Claude Code hooks are successfully connected to Slack!" \
                "good"
            echo "Test message sent!"
        else
            echo "Slack is not configured. Run: $0 configure"
        fi
        ;;
        
    "summary")
        # Send daily summary
        load_config
        if is_slack_configured; then
            generate_daily_summary
        fi
        ;;
        
    "monitor")
        # Continuous monitoring mode
        load_config
        echo "Starting Slack monitor..."
        while true; do
            check_performance_alerts
            process_queue
            sleep $BATCH_INTERVAL
        done
        ;;
        
    *)
        echo "Usage: $0 {notify|process|configure|test|summary|monitor}"
        echo ""
        echo "  notify    - Send a notification (called by hooks)"
        echo "  process   - Process queued messages"
        echo "  configure - Set up Slack webhook"
        echo "  test      - Test Slack connection"
        echo "  summary   - Send daily summary"
        echo "  monitor   - Run continuous monitoring"
        ;;
esac