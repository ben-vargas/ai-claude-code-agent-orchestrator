#!/bin/bash
# Agent Worker Script - Runs in individual terminals for parallel execution

AGENT_NAME=$1
SESSION_ID=$2
TASK_ID=$3

# Configuration
CLAUDE_DIR="$HOME/.claude"
SESSION_DIR="$CLAUDE_DIR/orchestration/session-$SESSION_ID"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_REQUIREMENTS="$PROJECT_DIR/agents/mcp-requirements.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Display header
echo -e "${BLUE}🤖 Claude Agent Worker${NC}"
echo -e "====================="
echo -e "Agent: ${YELLOW}$AGENT_NAME${NC}"
echo -e "Session: $SESSION_ID"
echo -e "Task: $TASK_ID"
echo ""

# Function to check agent-specific MCP requirements
check_agent_mcp_requirements() {
    echo -e "${CYAN}🔌 Checking MCP requirements for $AGENT_NAME${NC}"
    
    if [ ! -f "$MCP_REQUIREMENTS" ]; then
        echo -e "${YELLOW}⚠️  MCP requirements file not found${NC}"
        return 0
    fi
    
    # Check if agent has specific requirements
    local agent_reqs=$(jq -r ".agent_specific_requirements[\"$AGENT_NAME\"] // empty" "$MCP_REQUIREMENTS" 2>/dev/null)
    
    if [ -n "$agent_reqs" ]; then
        echo -e "${BLUE}Required MCP servers for $AGENT_NAME:${NC}"
        
        # Get configured servers
        local config_file="$CLAUDE_DIR/claude_code_config.json"
        if [ ! -f "$config_file" ]; then
            config_file="$CLAUDE_DIR/claude_desktop_config.json"
        fi
        
        local all_servers=""
        if [ -f "$config_file" ]; then
            all_servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null || echo "")
        fi
        
        # Check each required server
        local missing=false
        echo "$agent_reqs" | jq -r '.[]' | while read -r req; do
            if echo "$all_servers" | grep -q "^$req$"; then
                echo -e "   ${GREEN}✅ $req${NC}"
            else
                echo -e "   ${RED}❌ $req (missing)${NC}"
                missing=true
            fi
        done
        
        if [ "$missing" = true ]; then
            echo -e "${YELLOW}⚠️  Some MCP servers are missing. Agent may have limited functionality.${NC}"
        else
            echo -e "${GREEN}✅ All required MCP servers available${NC}"
        fi
    else
        echo -e "${CYAN}No specific MCP requirements for $AGENT_NAME${NC}"
    fi
    echo ""
}

# Check MCP requirements
check_agent_mcp_requirements

# Mark as active
touch "$SESSION_DIR/status/${AGENT_NAME}.active"

# Read task details
TASK_FILE="$SESSION_DIR/queue/${AGENT_NAME}.task"
if [ -f "$TASK_FILE" ]; then
    echo -e "${GREEN}✅ Task assignment found${NC}"
    cat "$TASK_FILE"
    echo ""
else
    echo -e "${RED}❌ No task assignment found${NC}"
    exit 1
fi

# Simulate agent work with Claude Code
echo -e "${BLUE}🚀 Starting Claude Code with ${AGENT_NAME} agent...${NC}"
echo ""

# Create agent prompt
AGENT_PROMPT="You are running as ${AGENT_NAME} in parallel execution mode.
Session ID: ${SESSION_ID}
Task ID: ${TASK_ID}

Please execute your specialized tasks and save results to:
${SESSION_DIR}/results/${AGENT_NAME}.json

Focus on your core expertise and complete the assigned work independently.
Other agents are running in parallel, so avoid dependencies where possible.

When complete, format your results as JSON with:
- status: 'completed' or 'failed'
- outputs: files or artifacts created
- insights: key findings (max 5)
- decisions: important choices made
- recommendations: for next steps
- duration: estimated time taken"

# Here you would actually launch Claude Code
# For demonstration, we'll simulate agent work
echo "$AGENT_PROMPT" > "$SESSION_DIR/logs/${AGENT_NAME}-prompt.txt"

# Simulate progress updates
for i in {1..5}; do
    progress=$((i * 20))
    echo -e "${YELLOW}Progress: ${progress}%${NC}"
    echo "{\"agent\": \"$AGENT_NAME\", \"progress\": $progress, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$SESSION_DIR/status/${AGENT_NAME}.progress"
    sleep 2
done

# Generate sample results (in real implementation, Claude would generate this)
cat > "$SESSION_DIR/results/${AGENT_NAME}.json" << EOF
{
    "agent": "$AGENT_NAME",
    "taskId": "$TASK_ID",
    "sessionId": "$SESSION_ID",
    "status": "completed",
    "startTime": "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)",
    "endTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "outputs": {
        "analysis": "$SESSION_DIR/outputs/${AGENT_NAME}-analysis.md",
        "recommendations": "$SESSION_DIR/outputs/${AGENT_NAME}-recommendations.md"
    },
    "insights": [
        "Key insight 1 from $AGENT_NAME",
        "Key insight 2 from $AGENT_NAME",
        "Key insight 3 from $AGENT_NAME"
    ],
    "decisions": {
        "primary": "Decision made by $AGENT_NAME",
        "rationale": "Reasoning for the decision"
    },
    "recommendations": [
        "Next step recommendation 1",
        "Next step recommendation 2"
    ],
    "metrics": {
        "duration": "5 minutes",
        "confidence": 0.95
    }
}
EOF

# Clean up
rm -f "$SESSION_DIR/status/${AGENT_NAME}.active"
rm -f "$SESSION_DIR/queue/${AGENT_NAME}.task"

echo ""
echo -e "${GREEN}✅ Agent work completed successfully!${NC}"
echo -e "Results saved to: ${YELLOW}$SESSION_DIR/results/${AGENT_NAME}.json${NC}"
echo ""
echo "This terminal will remain open for review."
echo "Press Enter to close..."
read