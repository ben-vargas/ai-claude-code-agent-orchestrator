#!/bin/bash
# Common Slack integration functions for all hooks

SLACK_NOTIFIER="$(dirname "$0")/slack-notifier.sh"

# Send notification to Slack if configured
notify_slack() {
    local event_type="$1"
    local agent_id="$2"
    local details="$3"
    local impact="${4:-medium}"
    
    # Check if slack notifier exists
    if [ -f "$SLACK_NOTIFIER" ]; then
        "$SLACK_NOTIFIER" notify "$event_type" "$agent_id" "$details" "$impact" &
    fi
}

# Send critical alert
alert_slack() {
    local agent_id="$1"
    local message="$2"
    
    notify_slack "error.critical" "$agent_id" "$message" "critical"
}

# Format tool error for Slack
format_tool_error() {
    local tool_name="$1"
    local error_msg="$2"
    echo "Tool: $tool_name - Error: ${error_msg:0:100}"
}

# Format progress update for Slack
format_progress() {
    local event="$1"
    local details="$2"
    echo "$details"
}

# Check if Slack notifications are enabled
is_slack_enabled() {
    [ -f "$HOME/.claude/hooks/slack-config.json" ] && \
    [ -n "$(jq -r '.webhook_url // ""' "$HOME/.claude/hooks/slack-config.json" 2>/dev/null)" ]
}