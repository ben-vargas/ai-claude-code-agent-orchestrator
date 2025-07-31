#!/bin/bash
# MCP Server Manager - Ensures MCP servers are available for Claude Code
# This script detects, validates, and manages MCP servers

set -e

# Configuration
CLAUDE_DIR="$HOME/.claude"
CLAUDE_DESKTOP_CONFIG="$CLAUDE_DIR/claude_desktop_config.json"
CLAUDE_CODE_CONFIG="$CLAUDE_DIR/claude_code_config.json"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is required but not installed${NC}"
        echo "Install with: brew install jq"
        exit 1
    fi
}

# Function to check if MCP config exists
check_mcp_configs() {
    local desktop_exists=false
    local code_exists=false
    
    if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
        desktop_exists=true
        echo -e "${GREEN}✅ Found Claude Desktop config${NC}"
    else
        echo -e "${YELLOW}⚠️  Claude Desktop config not found${NC}"
    fi
    
    if [ -f "$CLAUDE_CODE_CONFIG" ]; then
        code_exists=true
        echo -e "${GREEN}✅ Found Claude Code config${NC}"
    else
        echo -e "${YELLOW}⚠️  Claude Code config not found${NC}"
    fi
    
    if [ "$desktop_exists" = false ] && [ "$code_exists" = false ]; then
        echo -e "${RED}❌ No MCP configurations found${NC}"
        return 1
    fi
    
    return 0
}

# Function to list MCP servers from a config
list_mcp_servers() {
    local config_file=$1
    local config_name=$2
    
    if [ ! -f "$config_file" ]; then
        return
    fi
    
    echo -e "${BLUE}📋 MCP Servers in $config_name:${NC}"
    
    # Extract MCP server names
    local servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null || echo "")
    
    if [ -z "$servers" ]; then
        echo "   No MCP servers configured"
        return
    fi
    
    # List each server with details
    while IFS= read -r server; do
        local command=$(jq -r ".mcpServers[\"$server\"].command" "$config_file" 2>/dev/null || echo "unknown")
        local args=$(jq -r ".mcpServers[\"$server\"].args | join(\" \")" "$config_file" 2>/dev/null || echo "")
        
        echo -e "   ${GREEN}•${NC} $server"
        echo -e "     Command: ${CYAN}$command${NC}"
        if [ -n "$args" ] && [ "$args" != "null" ]; then
            echo -e "     Args: ${CYAN}$args${NC}"
        fi
    done <<< "$servers"
    echo ""
}

# Function to validate MCP server executable
validate_mcp_server() {
    local server_name=$1
    local command=$2
    local args=$3
    
    # Extract the actual executable path
    local executable=""
    
    if [[ "$command" == "node" ]] || [[ "$command" == "npx" ]]; then
        # For node/npx commands, check the script file
        executable=$(echo "$args" | awk '{print $1}')
    else
        executable="$command"
    fi
    
    # Expand home directory
    executable="${executable/#\~/$HOME}"
    
    # Check if executable exists
    if [ -f "$executable" ] || command -v "$(basename "$executable")" &> /dev/null; then
        echo -e "   ${GREEN}✅ Valid${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Not found: $executable${NC}"
        return 1
    fi
}

# Function to compare MCP servers between configs
compare_mcp_servers() {
    echo -e "${CYAN}🔍 Comparing MCP Server Configurations${NC}"
    echo -e "====================================="
    echo ""
    
    local desktop_servers=""
    local code_servers=""
    
    if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
        desktop_servers=$(jq -r '.mcpServers | keys[]' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null || echo "")
    fi
    
    if [ -f "$CLAUDE_CODE_CONFIG" ]; then
        code_servers=$(jq -r '.mcpServers | keys[]' "$CLAUDE_CODE_CONFIG" 2>/dev/null || echo "")
    fi
    
    # Find servers only in Desktop
    echo -e "${YELLOW}📥 Servers in Desktop but not in Code:${NC}"
    local missing_count=0
    
    if [ -n "$desktop_servers" ]; then
        while IFS= read -r server; do
            if [ -n "$server" ] && ! echo "$code_servers" | grep -q "^$server$"; then
                echo -e "   • $server"
                ((missing_count++))
            fi
        done <<< "$desktop_servers"
    fi
    
    if [ $missing_count -eq 0 ]; then
        echo "   None - all Desktop servers are in Code ✅"
    fi
    
    echo ""
    
    # Find servers only in Code
    echo -e "${BLUE}📤 Servers in Code but not in Desktop:${NC}"
    local code_only_count=0
    
    if [ -n "$code_servers" ]; then
        while IFS= read -r server; do
            if [ -n "$server" ] && ! echo "$desktop_servers" | grep -q "^$server$"; then
                echo -e "   • $server"
                ((code_only_count++))
            fi
        done <<< "$code_servers"
    fi
    
    if [ $code_only_count -eq 0 ]; then
        echo "   None"
    fi
    
    echo ""
    
    return $missing_count
}

# Function to copy MCP servers from Desktop to Code
copy_mcp_servers() {
    echo -e "${CYAN}📋 Copying MCP Servers from Desktop to Code${NC}"
    echo -e "=========================================="
    echo ""
    
    if [ ! -f "$CLAUDE_DESKTOP_CONFIG" ]; then
        echo -e "${RED}❌ Claude Desktop config not found${NC}"
        return 1
    fi
    
    # Create Code config if it doesn't exist
    if [ ! -f "$CLAUDE_CODE_CONFIG" ]; then
        echo -e "${YELLOW}Creating new Claude Code config...${NC}"
        echo '{"mcpServers": {}}' > "$CLAUDE_CODE_CONFIG"
    fi
    
    # Get Desktop servers
    local desktop_servers=$(jq -r '.mcpServers | keys[]' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null || echo "")
    
    if [ -z "$desktop_servers" ]; then
        echo -e "${YELLOW}No MCP servers found in Desktop config${NC}"
        return 0
    fi
    
    local copied_count=0
    
    # Copy each server
    while IFS= read -r server; do
        if [ -z "$server" ]; then
            continue
        fi
        
        # Check if server already exists in Code config
        local exists=$(jq -r ".mcpServers[\"$server\"] // empty" "$CLAUDE_CODE_CONFIG")
        
        if [ -z "$exists" ]; then
            echo -e "${BLUE}Copying $server...${NC}"
            
            # Extract server config from Desktop
            local server_config=$(jq ".mcpServers[\"$server\"]" "$CLAUDE_DESKTOP_CONFIG")
            
            # Add to Code config
            local tmp_config=$(mktemp)
            jq ".mcpServers[\"$server\"] = $server_config" "$CLAUDE_CODE_CONFIG" > "$tmp_config"
            mv "$tmp_config" "$CLAUDE_CODE_CONFIG"
            
            echo -e "${GREEN}✅ Copied $server${NC}"
            ((copied_count++))
        else
            echo -e "${CYAN}⏭️  Skipping $server (already exists)${NC}"
        fi
    done <<< "$desktop_servers"
    
    echo ""
    echo -e "${GREEN}✅ Copied $copied_count new MCP servers${NC}"
    
    return 0
}

# Function to validate all MCP servers
validate_all_servers() {
    echo -e "${CYAN}🔍 Validating MCP Servers${NC}"
    echo -e "========================"
    echo ""
    
    local all_valid=true
    
    for config_file in "$CLAUDE_DESKTOP_CONFIG" "$CLAUDE_CODE_CONFIG"; do
        if [ ! -f "$config_file" ]; then
            continue
        fi
        
        local config_name=$(basename "$config_file" .json)
        echo -e "${BLUE}Checking $config_name:${NC}"
        
        local servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null || echo "")
        
        if [ -z "$servers" ]; then
            echo "   No servers to validate"
            continue
        fi
        
        while IFS= read -r server; do
            if [ -z "$server" ]; then
                continue
            fi
            
            echo -n "   $server: "
            
            local command=$(jq -r ".mcpServers[\"$server\"].command" "$config_file" 2>/dev/null)
            local args=$(jq -r ".mcpServers[\"$server\"].args | join(\" \")" "$config_file" 2>/dev/null)
            
            if validate_mcp_server "$server" "$command" "$args"; then
                :
            else
                all_valid=false
            fi
        done <<< "$servers"
        
        echo ""
    done
    
    if [ "$all_valid" = true ]; then
        echo -e "${GREEN}✅ All MCP servers are valid${NC}"
        return 0
    else
        echo -e "${RED}❌ Some MCP servers have issues${NC}"
        return 1
    fi
}

# Function to create agent MCP requirements file
create_mcp_requirements() {
    local req_file="$PROJECT_DIR/agents/mcp-requirements.json"
    
    echo -e "${CYAN}📝 Creating MCP requirements file${NC}"
    
    cat > "$req_file" << 'EOF'
{
  "required_mcp_servers": {
    "filesystem": {
      "description": "File system operations",
      "critical": true,
      "alternatives": ["filesystem", "mcp-filesystem"]
    },
    "memory": {
      "description": "Persistent memory storage",
      "critical": true,
      "alternatives": ["sqlite-memory", "memory-keeper", "mcp-memory"]
    },
    "web": {
      "description": "Web browsing and search",
      "critical": false,
      "alternatives": ["playwright", "puppeteer", "brave-search", "web-fetch"]
    },
    "git": {
      "description": "Version control operations",
      "critical": false,
      "alternatives": ["git", "github", "gitlab"]
    }
  },
  "recommended_mcp_servers": [
    "sequential-thinking",
    "notion",
    "slack",
    "github",
    "postgres",
    "docker"
  ],
  "agent_specific_requirements": {
    "backend-expert": ["filesystem", "git", "postgres"],
    "frontend-expert": ["filesystem", "playwright", "git"],
    "devops-sre-expert": ["filesystem", "docker", "git"],
    "database-architect": ["postgres", "filesystem"],
    "qa-test-engineer": ["filesystem", "playwright", "git"]
  }
}
EOF
    
    echo -e "${GREEN}✅ Created MCP requirements at: $req_file${NC}"
}

# Function to check required MCP servers
check_required_servers() {
    local req_file="$PROJECT_DIR/agents/mcp-requirements.json"
    
    if [ ! -f "$req_file" ]; then
        create_mcp_requirements
    fi
    
    echo -e "${CYAN}🔍 Checking Required MCP Servers${NC}"
    echo -e "================================"
    echo ""
    
    # Get all configured servers
    local all_servers=""
    if [ -f "$CLAUDE_CODE_CONFIG" ]; then
        all_servers=$(jq -r '.mcpServers | keys[]' "$CLAUDE_CODE_CONFIG" 2>/dev/null || echo "")
    fi
    
    # Check critical requirements
    local missing_critical=false
    local critical_servers=$(jq -r '.required_mcp_servers | to_entries[] | select(.value.critical == true) | .key' "$req_file")
    
    echo -e "${RED}Critical MCP Servers:${NC}"
    while IFS= read -r req; do
        if [ -z "$req" ]; then
            continue
        fi
        
        local alternatives=$(jq -r ".required_mcp_servers[\"$req\"].alternatives[]" "$req_file" | tr '\n' ' ')
        local found=false
        
        for alt in $alternatives; do
            if echo "$all_servers" | grep -q "^$alt$"; then
                found=true
                echo -e "   ${GREEN}✅ $req: Found '$alt'${NC}"
                break
            fi
        done
        
        if [ "$found" = false ]; then
            echo -e "   ${RED}❌ $req: MISSING (need one of: $alternatives)${NC}"
            missing_critical=true
        fi
    done <<< "$critical_servers"
    
    echo ""
    
    # Check recommended servers
    echo -e "${YELLOW}Recommended MCP Servers:${NC}"
    local recommended=$(jq -r '.recommended_mcp_servers[]' "$req_file")
    
    while IFS= read -r rec; do
        if [ -z "$rec" ]; then
            continue
        fi
        
        if echo "$all_servers" | grep -q "^$rec$"; then
            echo -e "   ${GREEN}✅ $rec${NC}"
        else
            echo -e "   ${YELLOW}⚠️  $rec (not installed)${NC}"
        fi
    done <<< "$recommended"
    
    echo ""
    
    if [ "$missing_critical" = true ]; then
        echo -e "${RED}❌ Missing critical MCP servers!${NC}"
        echo -e "${YELLOW}Agents may not function properly without these servers.${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All critical MCP servers are available${NC}"
        return 0
    fi
}

# Main menu
show_menu() {
    echo -e "${CYAN}🔧 MCP Server Manager${NC}"
    echo -e "===================="
    echo ""
    echo "1. List all MCP servers"
    echo "2. Compare Desktop vs Code configs"
    echo "3. Copy servers from Desktop to Code"
    echo "4. Validate all MCP servers"
    echo "5. Check required MCP servers"
    echo "6. Full setup (copy & validate)"
    echo "7. Exit"
    echo ""
    echo -n "Select option: "
}

# Main execution
main() {
    check_jq
    
    if [ "$1" == "--auto" ] || [ "$1" == "-a" ]; then
        # Automatic mode - copy and validate
        echo -e "${CYAN}🤖 Running automatic MCP setup${NC}"
        echo ""
        
        if check_mcp_configs; then
            compare_mcp_servers
            if [ $? -gt 0 ]; then
                copy_mcp_servers
            fi
            validate_all_servers
            check_required_servers
        else
            echo -e "${RED}❌ Cannot proceed without MCP configurations${NC}"
            exit 1
        fi
        
        exit 0
    fi
    
    # Interactive mode
    while true; do
        show_menu
        read -r choice
        echo ""
        
        case $choice in
            1)
                check_mcp_configs
                list_mcp_servers "$CLAUDE_DESKTOP_CONFIG" "Claude Desktop"
                list_mcp_servers "$CLAUDE_CODE_CONFIG" "Claude Code"
                ;;
            2)
                check_mcp_configs && compare_mcp_servers
                ;;
            3)
                copy_mcp_servers
                ;;
            4)
                validate_all_servers
                ;;
            5)
                check_required_servers
                ;;
            6)
                echo -e "${CYAN}🚀 Running full MCP setup${NC}"
                echo ""
                if check_mcp_configs; then
                    compare_mcp_servers
                    if [ $? -gt 0 ]; then
                        echo ""
                        read -p "Copy missing servers from Desktop to Code? (y/N) " -n 1 -r
                        echo ""
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            copy_mcp_servers
                        fi
                    fi
                    echo ""
                    validate_all_servers
                    echo ""
                    check_required_servers
                fi
                ;;
            7)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo ""
        echo "Press Enter to continue..."
        read -r
        clear
    done
}

# Run main
main "$@"