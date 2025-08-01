#!/bin/bash

# Orchestrator Integration Script for Dashboard
# This script provides webhook notifications to the dashboard

WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:3001/api/webhooks/notify}"
EXECUTION_ID="${EXECUTION_ID:-$(uuidgen)}"
PROJECT_ID="${PROJECT_ID:-default}"

# Send webhook notification
notify_dashboard() {
    local event=$1
    local data=$2
    
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"$event\",
            \"executionId\": \"$EXECUTION_ID\",
            \"projectId\": \"$PROJECT_ID\",
            \"data\": $data,
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
        }" \
        -s > /dev/null
}

# Execution lifecycle hooks
on_execution_start() {
    local plan=$1
    notify_dashboard "execution:started" "{\"plan\": $plan}"
}

on_execution_progress() {
    local progress=$1
    local current_agent=$2
    local completed_agents=$3
    
    notify_dashboard "execution:progress" "{
        \"progress\": $progress,
        \"currentAgent\": \"$current_agent\",
        \"completedAgents\": $completed_agents
    }"
}

on_execution_complete() {
    local status=$1
    local summary=$2
    
    notify_dashboard "execution:completed" "{
        \"status\": \"$status\",
        \"summary\": $summary
    }"
}

# Agent lifecycle hooks
on_agent_start() {
    local agent_name=$1
    local task_id=$2
    local input=$3
    
    notify_dashboard "agent:started" "{
        \"agentName\": \"$agent_name\",
        \"taskId\": \"$task_id\",
        \"input\": $input
    }"
}

on_agent_complete() {
    local agent_name=$1
    local task_id=$2
    local status=$3
    local output=$4
    
    notify_dashboard "agent:completed" "{
        \"agentName\": \"$agent_name\",
        \"taskId\": \"$task_id\",
        \"status\": \"$status\",
        \"output\": $output
    }"
}

# Logging hook
on_log() {
    local level=$1
    local agent_name=$2
    local message=$3
    local metadata=${4:-{}}
    
    notify_dashboard "agent:log" "{
        \"level\": \"$level\",
        \"agentName\": \"$agent_name\",
        \"message\": \"$message\",
        \"metadata\": $metadata
    }"
}

# Metric hook
on_metric() {
    local metric_name=$1
    local metric_value=$2
    
    notify_dashboard "metric:update" "{
        \"metricName\": \"$metric_name\",
        \"metricValue\": $metric_value
    }"
}

# Export functions for use in orchestrator
export -f notify_dashboard
export -f on_execution_start
export -f on_execution_progress
export -f on_execution_complete
export -f on_agent_start
export -f on_agent_complete
export -f on_log
export -f on_metric

echo "Dashboard integration loaded. Webhook URL: $WEBHOOK_URL"