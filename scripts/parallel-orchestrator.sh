#!/bin/bash
# Claude Code Agent Orchestrator - Parallel Execution System
# This script manages multiple Claude terminals for true parallel agent execution

set -e

# Configuration
CLAUDE_DIR="$HOME/.claude"
ORCH_BASE="$CLAUDE_DIR/orchestration"
SESSION_ID="orch-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="$ORCH_BASE/session-$SESSION_ID"

# Default values
PROJECT_NAME="${1:-Untitled Project}"
PROJECT_LEVEL="${2:-3}"
MAX_TERMINALS="${3:-3}"
INTERACTIVE="${4:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create session directory structure
initialize_session() {
    echo -e "${CYAN}🎭 Initializing Parallel Orchestration Session${NC}"
    echo -e "Session ID: ${YELLOW}$SESSION_ID${NC}"
    
    mkdir -p "$SESSION_DIR"/{status,results,logs,queue,locks}
    
    # Create session configuration
    cat > "$SESSION_DIR/config.json" << EOF
{
    "sessionId": "$SESSION_ID",
    "projectName": "$PROJECT_NAME",
    "projectLevel": $PROJECT_LEVEL,
    "maxTerminals": $MAX_TERMINALS,
    "interactive": $INTERACTIVE,
    "startTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "initializing",
    "orchestrationMode": "parallel",
    "terminals": []
}
EOF

    # Initialize status file
    cat > "$SESSION_DIR/status/orchestration.yaml" << EOF
session_id: "$SESSION_ID"
project: "$PROJECT_NAME"
level: $PROJECT_LEVEL
phase: 0
status: initializing
active_terminals: 0
max_terminals: $MAX_TERMINALS
agents_queued: []
agents_active: []
agents_completed: []
start_time: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF

    echo -e "${GREEN}✅ Session initialized${NC}"
}

# Function to spawn an agent in a new terminal
spawn_agent_terminal() {
    local agent_name=$1
    local task_id=$2
    local phase=$3
    
    echo -e "${BLUE}🚀 Spawning terminal for ${agent_name}${NC}"
    
    # Create task file for agent
    cat > "$SESSION_DIR/queue/${agent_name}.task" << EOF
{
    "taskId": "$task_id",
    "agent": "$agent_name",
    "phase": $phase,
    "sessionId": "$SESSION_ID",
    "assignedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "assigned"
}
EOF

    # macOS Terminal spawn
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript <<EOF
tell application "Terminal"
    set newWindow to do script "cd '$PWD' && $CLAUDE_DIR/scripts/agent-worker.sh '$agent_name' '$SESSION_ID' '$task_id'"
    set custom title of newWindow to "🤖 $agent_name [Phase $phase]"
    
    -- Optional: Arrange windows
    set bounds of front window to {100, 100, 800, 600}
end tell
EOF
    else
        # Linux/Other - use gnome-terminal or xterm
        gnome-terminal --title="🤖 $agent_name [Phase $phase]" -- bash -c "cd '$PWD' && $CLAUDE_DIR/scripts/agent-worker.sh '$agent_name' '$SESSION_ID' '$task_id'; read -p 'Press enter to close...'"
    fi
    
    # Update active agents
    echo "$agent_name" >> "$SESSION_DIR/status/active_agents.txt"
    
    # Log spawn event
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - Spawned $agent_name (task: $task_id)" >> "$SESSION_DIR/logs/orchestration.log"
}

# Monitor active terminals
monitor_terminals() {
    local active_count=$(ls -1 "$SESSION_DIR/status/"*.active 2>/dev/null | wc -l)
    echo $active_count
}

# Wait for available terminal slot
wait_for_terminal_slot() {
    while [ $(monitor_terminals) -ge $MAX_TERMINALS ]; do
        echo -e "${YELLOW}⏳ All terminals busy. Waiting for slot...${NC}"
        sleep 5
        
        # Check for completed agents
        check_completed_agents
    done
}

# Check for completed agents
check_completed_agents() {
    for result_file in "$SESSION_DIR/results"/*.json; do
        if [ -f "$result_file" ]; then
            local agent_name=$(basename "$result_file" .json)
            if [ -f "$SESSION_DIR/status/${agent_name}.active" ]; then
                rm -f "$SESSION_DIR/status/${agent_name}.active"
                echo -e "${GREEN}✅ ${agent_name} completed${NC}"
                
                # Process results
                process_agent_results "$agent_name"
            fi
        fi
    done
}

# Process agent results and update progress
process_agent_results() {
    local agent_name=$1
    local result_file="$SESSION_DIR/results/${agent_name}.json"
    
    # Extract key information from results
    local status=$(jq -r '.status' "$result_file" 2>/dev/null || echo "unknown")
    local insights=$(jq -r '.insights[]' "$result_file" 2>/dev/null || echo "")
    
    # Update orchestration plan
    echo -e "${PURPLE}📊 Processing results from ${agent_name}${NC}"
    
    # Log completion
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - Completed $agent_name (status: $status)" >> "$SESSION_DIR/logs/orchestration.log"
}

# Display progress dashboard
show_progress() {
    clear
    echo -e "${CYAN}🎭 PARALLEL ORCHESTRATION PROGRESS${NC}"
    echo -e "=================================="
    echo -e "Session: ${YELLOW}$SESSION_ID${NC}"
    echo -e "Project: $PROJECT_NAME (Level $PROJECT_LEVEL)"
    echo ""
    
    # Active terminals
    local active_count=$(monitor_terminals)
    echo -e "${GREEN}ACTIVE TERMINALS [$active_count/$MAX_TERMINALS]${NC}"
    
    for active_file in "$SESSION_DIR/status/"*.active; do
        if [ -f "$active_file" ]; then
            local agent=$(basename "$active_file" .active)
            local start_time=$(stat -f "%Sm" -t "%H:%M:%S" "$active_file" 2>/dev/null || echo "unknown")
            echo -e "  🔄 $agent (started: $start_time)"
        fi
    done
    
    echo ""
    
    # Completed agents
    local completed_count=$(ls -1 "$SESSION_DIR/results"/*.json 2>/dev/null | wc -l)
    echo -e "${GREEN}COMPLETED [$completed_count]${NC}"
    
    for result_file in "$SESSION_DIR/results"/*.json; do
        if [ -f "$result_file" ]; then
            local agent=$(basename "$result_file" .json)
            echo -e "  ✅ $agent"
        fi
    done
    
    echo ""
    
    # Queued agents
    local queued_count=$(ls -1 "$SESSION_DIR/queue"/*.task 2>/dev/null | wc -l)
    if [ $queued_count -gt 0 ]; then
        echo -e "${YELLOW}QUEUED [$queued_count]${NC}"
        for task_file in "$SESSION_DIR/queue"/*.task; do
            if [ -f "$task_file" ]; then
                local agent=$(basename "$task_file" .task)
                echo -e "  ⏳ $agent"
            fi
        done
    fi
}

# Check MCP servers before starting
check_mcp_servers() {
    echo -e "${CYAN}🔌 Checking MCP Servers${NC}"
    echo -e "──────────────────────"
    
    local mcp_script="$CLAUDE_DIR/../Claude-Code-Agent-Orchestrator/scripts/mcp-server-manager.sh"
    
    if [ -f "$mcp_script" ]; then
        # Check required servers
        if ! "$mcp_script" --auto > /dev/null 2>&1; then
            echo -e "${RED}❌ Critical MCP servers are missing!${NC}"
            echo -e "${YELLOW}Some agents may not function properly.${NC}"
            echo ""
            echo "Run './scripts/mcp-server-manager.sh' to set up MCP servers"
            echo ""
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            echo -e "${GREEN}✅ MCP servers configured${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Cannot verify MCP servers${NC}"
        echo "   Agents may have limited functionality"
    fi
    echo ""
}

# Main orchestration loop
main() {
    echo -e "${CYAN}🎭 Claude Code Agent Orchestrator - Parallel Execution${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo ""
    
    # Check MCP servers first
    check_mcp_servers
    
    # Initialize session
    initialize_session
    
    # Create example parallel phase (this would come from orchestration plan)
    # In real implementation, this would be generated by the orchestration agent
    cat > "$SESSION_DIR/phase-1-plan.json" << EOF
{
    "phase": 1,
    "name": "Research & Analysis",
    "agents": [
        {"name": "business-analyst", "taskId": "task-001", "dependencies": []},
        {"name": "competitive-intelligence-expert", "taskId": "task-002", "dependencies": []},
        {"name": "market-research-expert", "taskId": "task-003", "dependencies": []},
        {"name": "technical-feasibility-expert", "taskId": "task-004", "dependencies": []}
    ]
}
EOF
    
    echo -e "${BLUE}📋 Starting Phase 1: Research & Analysis${NC}"
    echo -e "Parallel agents: 4"
    echo ""
    
    # Queue all agents for phase 1
    for i in {0..3}; do
        agent_name=$(jq -r ".agents[$i].name" "$SESSION_DIR/phase-1-plan.json")
        task_id=$(jq -r ".agents[$i].taskId" "$SESSION_DIR/phase-1-plan.json")
        
        # Wait for available slot
        wait_for_terminal_slot
        
        # Spawn agent
        spawn_agent_terminal "$agent_name" "$task_id" 1
        
        # Brief delay between spawns
        sleep 2
    done
    
    # Monitor progress
    echo ""
    echo -e "${CYAN}📊 Monitoring progress...${NC}"
    echo -e "Press Ctrl+C to stop monitoring (agents will continue running)"
    echo ""
    
    # Progress monitoring loop
    while true; do
        show_progress
        sleep 5
        
        # Check if all agents completed
        local completed=$(ls -1 "$SESSION_DIR/results"/*.json 2>/dev/null | wc -l)
        local total=4  # Would be dynamic in real implementation
        
        if [ $completed -eq $total ]; then
            echo ""
            echo -e "${GREEN}🎉 Phase 1 Complete!${NC}"
            echo -e "All agents have finished their tasks."
            break
        fi
    done
    
    # Generate summary
    echo ""
    echo -e "${CYAN}📊 Phase Summary${NC}"
    echo -e "================"
    echo -e "Total agents: 4"
    echo -e "Completed: $completed"
    echo -e "Duration: $(calculate_duration)"
    echo ""
    echo -e "Results saved to: ${YELLOW}$SESSION_DIR${NC}"
}

# Calculate phase duration
calculate_duration() {
    local start_file="$SESSION_DIR/status/orchestration.yaml"
    if [ -f "$start_file" ]; then
        local start_time=$(grep "start_time:" "$start_file" | cut -d'"' -f2)
        local end_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        # Simple duration calc (would be more sophisticated in real implementation)
        echo "~15 minutes"
    else
        echo "unknown"
    fi
}

# Cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    # Remove active status files
    rm -f "$SESSION_DIR/status/"*.active
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Set trap for cleanup
trap cleanup EXIT

# Run main orchestration
main "$@"