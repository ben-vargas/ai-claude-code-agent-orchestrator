#!/bin/bash
# Show all available tools and MCP servers for Claude Code

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🛠️  Claude Code Tools & MCP Servers${NC}"
echo "===================================="
echo ""

# Show core tools
show_core_tools() {
    echo -e "${BLUE}📦 Core Tools (Always Available)${NC}"
    echo "--------------------------------"
    
    echo -e "\n${CYAN}File Operations:${NC}"
    echo "  • Read - Read file contents with line numbers"
    echo "  • Write - Create or overwrite files"
    echo "  • Edit - Replace text in files"
    echo "  • MultiEdit - Multiple edits to a single file"
    echo "  • NotebookRead - Read Jupyter notebooks"
    echo "  • NotebookEdit - Edit Jupyter notebooks"
    
    echo -e "\n${CYAN}Search & Navigation:${NC}"
    echo "  • Grep - Regex search (ripgrep-based)"
    echo "  • Glob - Find files by pattern"
    echo "  • LS - List directory contents"
    echo "  • WebSearch - Search the web"
    echo "  • WebFetch - Fetch web content"
    
    echo -e "\n${CYAN}Code Execution:${NC}"
    echo "  • Bash - Execute shell commands"
    echo "  • ExitPlanMode - Exit planning mode"
    
    echo -e "\n${CYAN}Project Management:${NC}"
    echo "  • TodoWrite - Manage task lists"
    echo "  • Task - Launch specialized agents"
}

# Check MCP servers
check_mcp_servers() {
    echo -e "\n${BLUE}🔌 MCP Servers${NC}"
    echo "--------------"
    
    local config_file="$HOME/.claude/claude_desktop_config.json"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ MCP configuration not found${NC}"
        echo "   File not found: $config_file"
        return
    fi
    
    # Extract MCP server names
    if command -v jq &> /dev/null; then
        echo -e "\n${CYAN}Configured MCP Servers:${NC}"
        
        # Get list of servers
        servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null || echo "")
        
        if [ -z "$servers" ]; then
            echo -e "${YELLOW}  No MCP servers configured${NC}"
        else
            while IFS= read -r server; do
                # Get server command
                cmd=$(jq -r ".mcpServers[\"$server\"].command" "$config_file" 2>/dev/null)
                
                # Check if executable exists
                if [ -n "$cmd" ]; then
                    if command -v "$cmd" &> /dev/null || [ -f "$cmd" ]; then
                        echo -e "  ${GREEN}✅ $server${NC}"
                        
                        # Show server details based on name
                        case "$server" in
                            "filesystem")
                                echo "     └─ File operations (read, write, edit, search)"
                                ;;
                            "memory")
                                echo "     └─ Knowledge graph & persistent memory"
                                ;;
                            "firecrawl"*)
                                echo "     └─ Web scraping & research"
                                ;;
                            "playwright")
                                echo "     └─ Browser automation"
                                ;;
                            "notionApi")
                                echo "     └─ Notion integration"
                                ;;
                            "taskmaster-ai")
                                echo "     └─ Task management & orchestration"
                                ;;
                            "sequential-thinking")
                                echo "     └─ Step-by-step problem solving"
                                ;;
                            "context7")
                                echo "     └─ Library documentation"
                                ;;
                            *)
                                echo "     └─ Custom MCP server"
                                ;;
                        esac
                    else
                        echo -e "  ${YELLOW}⚠️  $server${NC} (executable not found: $cmd)"
                    fi
                else
                    echo -e "  ${YELLOW}⚠️  $server${NC} (no command specified)"
                fi
            done <<< "$servers"
        fi
    else
        echo -e "${YELLOW}⚠️  jq not installed - showing raw config${NC}"
        echo ""
        grep -E '"[^"]+"\s*:\s*{' "$config_file" | sed 's/.*"\([^"]*\)".*/  • \1/'
    fi
}

# Check available agents
check_agents() {
    echo -e "\n${BLUE}🤖 Available Agents${NC}"
    echo "------------------"
    
    local agents_dir="$HOME/.claude/agents"
    
    if [ ! -d "$agents_dir" ]; then
        echo -e "${RED}❌ Agents directory not found${NC}"
        return
    fi
    
    # Count agent files
    local agent_count=$(ls -1 "$agents_dir"/*.md 2>/dev/null | grep -v -E "(registry|schema|adapter)" | wc -l)
    
    if [ "$agent_count" -eq 0 ]; then
        echo -e "${YELLOW}No agents installed${NC}"
        return
    fi
    
    echo -e "${GREEN}✅ $agent_count specialized agents available${NC}"
    
    # Group agents by category
    echo -e "\n${CYAN}Engineering:${NC}"
    for agent in backend-expert frontend-expert mobile-expert database-architect devops-sre-expert performance-engineer; do
        [ -f "$agents_dir/$agent.md" ] && echo "  • $agent"
    done
    
    echo -e "\n${CYAN}Business & Strategy:${NC}"
    for agent in business-analyst product-strategy-expert pricing-optimization-expert competitive-intelligence-expert; do
        [ -f "$agents_dir/$agent.md" ] && echo "  • $agent"
    done
    
    echo -e "\n${CYAN}Design & Marketing:${NC}"
    for agent in uiux-expert marketing-expert social-media-expert customer-success-expert; do
        [ -f "$agents_dir/$agent.md" ] && echo "  • $agent"
    done
    
    echo -e "\n${CYAN}Security & Operations:${NC}"
    for agent in security-specialist cloud-security-auditor business-operations-expert legal-compliance-expert; do
        [ -f "$agents_dir/$agent.md" ] && echo "  • $agent"
    done
    
    echo -e "\n${CYAN}Specialized:${NC}"
    for agent in ai-ml-expert blockchain-expert data-analytics-expert qa-test-engineer orchestration-agent; do
        [ -f "$agents_dir/$agent.md" ] && echo "  • $agent"
    done
}

# Show quick stats
show_stats() {
    echo -e "\n${BLUE}📊 Quick Stats${NC}"
    echo "--------------"
    
    # Core tools count
    echo -e "Core Tools: ${GREEN}14${NC} always available"
    
    # MCP server count
    local mcp_count=0
    if [ -f "$HOME/.claude/claude_desktop_config.json" ]; then
        if command -v jq &> /dev/null; then
            mcp_count=$(jq -r '.mcpServers | length' "$HOME/.claude/claude_desktop_config.json" 2>/dev/null || echo "0")
        fi
    fi
    echo -e "MCP Servers: ${GREEN}$mcp_count${NC} configured"
    
    # Agent count
    local agent_count=0
    if [ -d "$HOME/.claude/agents" ]; then
        agent_count=$(ls -1 "$HOME/.claude/agents"/*.md 2>/dev/null | grep -v -E "(registry|schema|adapter)" | wc -l)
    fi
    echo -e "AI Agents: ${GREEN}$agent_count${NC} available"
    
    # Memory status
    if [ -f "$HOME/.claude/agent-memory/agent-collaboration.db" ]; then
        echo -e "Memory: ${GREEN}SQLite${NC} active"
    else
        echo -e "Memory: ${YELLOW}Filesystem${NC} fallback"
    fi
}

# Show usage tips
show_tips() {
    echo -e "\n${BLUE}💡 Usage Tips${NC}"
    echo "-------------"
    echo "• Use core tools for direct file/web operations"
    echo "• Use MCP servers for enhanced capabilities"
    echo "• Use Task tool to launch specialized agents"
    echo "• Combine tools for complex workflows"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo '  Grep pattern="TODO" glob="**/*.js"'
    echo '  Task subagent_type="backend-expert" prompt="Design API"'
    echo '  mcp__filesystem__read_file path="/path/to/file"'
}

# Main execution
main() {
    # Show all sections
    show_core_tools
    check_mcp_servers
    check_agents
    show_stats
    show_tips
    
    echo -e "\n${PURPLE}For detailed tool documentation, use:${NC}"
    echo "  • Individual tool help in Claude Code"
    echo "  • MCP server documentation"
    echo "  • Agent definition files in ~/.claude/agents/"
    echo ""
}

# Run main
main