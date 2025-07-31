#!/bin/bash
# Claude Code Agent Orchestrator - Main Orchestration Script
# This script manages agent orchestration with project levels and interactive mode

set -e

# Configuration
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
WORKSPACES_DIR="$CLAUDE_DIR/agent-workspaces"
ORCHESTRATION_LOG="$WORKSPACES_DIR/orchestration.log"
MCP_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mcp-server-manager.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME="${1:-Untitled Project}"
PROJECT_LEVEL="${2:-3}"
INTERACTIVE="${3:-true}"
TIMEOUT_MINUTES="${4:-5}"

# Validate project level
if ! [[ "$PROJECT_LEVEL" =~ ^[1-5]$ ]]; then
    echo -e "${RED}❌ Invalid project level: $PROJECT_LEVEL${NC}"
    echo "   Please specify a level between 1 (MVP) and 5 (Enterprise)"
    exit 1
fi

# Function to log with timestamp
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$ORCHESTRATION_LOG"
    echo -e "$message"
}

# Function to check MCP servers
check_mcp_servers() {
    log "${CYAN}🔌 Checking MCP Servers${NC}"
    echo -e "──────────────────────"
    
    if [ -f "$MCP_SCRIPT" ]; then
        # Check required servers
        if ! "$MCP_SCRIPT" --auto > /dev/null 2>&1; then
            log "${RED}❌ Critical MCP servers are missing!${NC}"
            log "${YELLOW}Some agents may not function properly.${NC}"
            echo ""
            echo "Run './scripts/mcp-server-manager.sh' to set up MCP servers"
            echo ""
            
            if [ "$INTERACTIVE" = "true" ]; then
                read -p "Continue anyway? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            else
                log "${YELLOW}⚠️  Non-interactive mode: continuing despite missing servers${NC}"
            fi
        else
            log "${GREEN}✅ MCP servers configured${NC}"
        fi
    else
        log "${YELLOW}⚠️  Cannot verify MCP servers${NC}"
        echo "   Agents may have limited functionality"
    fi
    echo ""
}

# Function to display project level details
display_project_level() {
    echo -e "${BLUE}📊 Project Level: $PROJECT_LEVEL${NC}"
    case $PROJECT_LEVEL in
        1)
            echo "   ${CYAN}MVP - Minimum Viable Product${NC}"
            echo "   • Focus: Core functionality only"
            echo "   • Quality: Basic implementation"
            echo "   • Testing: Minimal"
            ;;
        2)
            echo "   ${CYAN}Beta - Early Access${NC}"
            echo "   • Focus: Key features complete"
            echo "   • Quality: Some polish, known issues OK"
            echo "   • Testing: Basic test coverage"
            ;;
        3)
            echo "   ${GREEN}Alpha - Production Ready${NC}"
            echo "   • Focus: Full feature set"
            echo "   • Quality: Well-tested, documented"
            echo "   • Testing: Comprehensive coverage"
            ;;
        4)
            echo "   ${YELLOW}Production - High Quality${NC}"
            echo "   • Focus: Performance & reliability"
            echo "   • Quality: Optimized, secure"
            echo "   • Testing: Full test suite + monitoring"
            ;;
        5)
            echo "   ${PURPLE}Enterprise - Mission Critical${NC}"
            echo "   • Focus: Scalability & compliance"
            echo "   • Quality: Enterprise-grade"
            echo "   • Testing: Exhaustive + security audits"
            ;;
    esac
    echo ""
}

# Function to wait for user input with timeout
wait_for_user_input() {
    local prompt="$1"
    local default_action="$2"
    local timeout_seconds=$((TIMEOUT_MINUTES * 60))
    
    if [ "$INTERACTIVE" != "true" ]; then
        log "${CYAN}Non-interactive mode: proceeding with $default_action${NC}"
        echo "$default_action"
        return 0
    fi
    
    echo -e "${YELLOW}$prompt${NC}"
    echo -e "${CYAN}You have $TIMEOUT_MINUTES minutes to respond (default: $default_action)${NC}"
    
    # Read with timeout
    local response=""
    if read -t $timeout_seconds -r response; then
        if [ -z "$response" ]; then
            echo "$default_action"
        else
            echo "$response"
        fi
    else
        echo ""
        log "${CYAN}⏱️  Timeout reached. Auto-proceeding with: $default_action${NC}"
        echo "$default_action"
    fi
}

# Function to initialize orchestration
initialize_orchestration() {
    log "${CYAN}🎭 Initializing Orchestration${NC}"
    
    # Create workspace directory
    mkdir -p "$WORKSPACES_DIR"
    
    # Create orchestration agent workspace
    local orch_workspace="$WORKSPACES_DIR/Agent-orchestration.md"
    cat > "$orch_workspace" << EOF
# Orchestration Agent Workspace

## Project Details
- **Name**: $PROJECT_NAME
- **Level**: $PROJECT_LEVEL
- **Started**: $(date)
- **Mode**: $([ "$INTERACTIVE" = "true" ] && echo "Interactive" || echo "Automatic")
- **Timeout**: $TIMEOUT_MINUTES minutes

## Active Tasks
EOF
    
    log "${GREEN}✅ Orchestration initialized${NC}"
}

# Function to run orchestration phase
run_orchestration_phase() {
    local phase="$1"
    local agents=("${@:2}")
    
    log "${BLUE}📋 Phase: $phase${NC}"
    log "Agents: ${agents[*]}"
    
    # In interactive mode, ask for confirmation
    if [ "$INTERACTIVE" = "true" ]; then
        local response=$(wait_for_user_input "Proceed with this phase? (y/n)" "y")
        if [[ ! $response =~ ^[yY]$ ]]; then
            log "${YELLOW}Phase skipped by user${NC}"
            return 1
        fi
    fi
    
    # Execute agents (simulated for now)
    for agent in "${agents[@]}"; do
        log "${CYAN}🤖 Running $agent...${NC}"
        
        # Create agent task file
        local agent_workspace="$WORKSPACES_DIR/Agent-$agent.md"
        echo "## Task: $phase" >> "$agent_workspace"
        echo "Started: $(date)" >> "$agent_workspace"
        echo "Project Level: $PROJECT_LEVEL" >> "$agent_workspace"
        echo "" >> "$agent_workspace"
        
        # Simulate agent execution
        sleep 2
        
        log "${GREEN}✅ $agent completed${NC}"
    done
    
    return 0
}

# Function to generate orchestration plan
generate_orchestration_plan() {
    log "${CYAN}📊 Generating Orchestration Plan${NC}"
    log "Project: $PROJECT_NAME (Level $PROJECT_LEVEL)"
    
    # Basic orchestration phases based on project type
    local phases=(
        "Research & Analysis:business-analyst,competitive-intelligence-expert"
        "Architecture Design:cloud-architect,database-architect"
        "Implementation:backend-expert,frontend-expert"
        "Testing & QA:qa-test-engineer,security-specialist"
        "Deployment:devops-sre-expert,cloud-security-auditor"
    )
    
    # Adjust phases based on project level
    if [ "$PROJECT_LEVEL" -le 2 ]; then
        # MVP/Beta - skip some phases
        phases=(
            "Quick Analysis:business-analyst"
            "Basic Implementation:backend-expert,frontend-expert"
            "Basic Testing:qa-test-engineer"
        )
    elif [ "$PROJECT_LEVEL" -ge 4 ]; then
        # Production/Enterprise - add more phases
        phases+=(
            "Performance Optimization:performance-engineer"
            "Security Audit:security-specialist,cloud-security-auditor"
            "Documentation:uiux-expert,customer-success-expert"
        )
    fi
    
    # Display plan
    echo ""
    echo -e "${PURPLE}📋 Orchestration Plan:${NC}"
    for i in "${!phases[@]}"; do
        IFS=':' read -r phase agents <<< "${phases[$i]}"
        echo -e "${CYAN}Phase $((i+1)): $phase${NC}"
        echo -e "   Agents: ${YELLOW}$agents${NC}"
    done
    echo ""
    
    # In interactive mode, allow plan modification
    if [ "$INTERACTIVE" = "true" ]; then
        local response=$(wait_for_user_input "Approve this plan? (y/n/modify)" "y")
        if [[ $response =~ ^[mM] ]]; then
            log "${YELLOW}Plan modification requested - not yet implemented${NC}"
        elif [[ ! $response =~ ^[yY]$ ]]; then
            log "${RED}Plan rejected by user${NC}"
            exit 1
        fi
    fi
    
    # Execute phases
    for phase_info in "${phases[@]}"; do
        IFS=':' read -r phase agents <<< "$phase_info"
        IFS=',' read -ra agent_array <<< "$agents"
        
        if ! run_orchestration_phase "$phase" "${agent_array[@]}"; then
            log "${YELLOW}⚠️  Phase '$phase' was skipped${NC}"
        fi
        
        echo ""
    done
}

# Function to summarize results
summarize_orchestration() {
    log "${CYAN}📊 Orchestration Summary${NC}"
    echo -e "========================"
    
    echo -e "${BLUE}Project:${NC} $PROJECT_NAME"
    echo -e "${BLUE}Level:${NC} $PROJECT_LEVEL"
    echo -e "${BLUE}Duration:${NC} $(date -d @$(($(date +%s) - START_TIME)) -u +%H:%M:%S)"
    echo ""
    
    # Count completed tasks
    local completed_count=$(grep -c "✅" "$ORCHESTRATION_LOG" || true)
    local skipped_count=$(grep -c "skipped" "$ORCHESTRATION_LOG" || true)
    
    echo -e "${GREEN}Completed:${NC} $completed_count tasks"
    echo -e "${YELLOW}Skipped:${NC} $skipped_count tasks"
    echo ""
    
    echo -e "${CYAN}📁 Results saved to:${NC}"
    echo "   $WORKSPACES_DIR"
    echo "   $ORCHESTRATION_LOG"
}

# Main execution
main() {
    START_TIME=$(date +%s)
    
    echo -e "${CYAN}🎭 Claude Code Agent Orchestrator${NC}"
    echo -e "${CYAN}====================================${NC}"
    echo ""
    
    # Check prerequisites
    if [ ! -d "$AGENTS_DIR" ]; then
        echo -e "${RED}❌ Agents directory not found at: $AGENTS_DIR${NC}"
        echo "   Please run install.sh first"
        exit 1
    fi
    
    # Check MCP servers
    check_mcp_servers
    
    # Display project information
    echo -e "${BLUE}Project: $PROJECT_NAME${NC}"
    display_project_level
    
    # Initialize orchestration
    initialize_orchestration
    
    # Generate and execute orchestration plan
    generate_orchestration_plan
    
    # Summarize results
    summarize_orchestration
    
    echo ""
    echo -e "${GREEN}🎉 Orchestration Complete!${NC}"
}

# Run main function
main "$@"