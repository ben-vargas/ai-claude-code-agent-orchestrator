#!/bin/bash
# Test multiple Claude Code instances with MCP servers

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Multiple Claude Code Instance Test${NC}"
echo "======================================"
echo ""

# Test configuration
CLAUDE_DIR="$HOME/.claude"
INSTANCE_COUNT=3
TEST_PROJECT="multi-agent-test"
WORKSPACE_DIR="$HOME/test-claude-instances"

# Function to check if Claude is installed
check_claude_installation() {
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}❌ Claude Code CLI not found${NC}"
        echo "Please install Claude Code: https://claude.ai/download"
        exit 1
    fi
    echo -e "${GREEN}✅ Claude Code CLI found${NC}"
}

# Function to check MCP servers
check_mcp_servers() {
    echo -e "\n${CYAN}Checking MCP servers...${NC}"
    
    local config_file="$CLAUDE_DIR/claude_desktop_config.json"
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ MCP config not found${NC}"
        return 1
    fi
    
    # Check for critical MCP servers
    local critical_servers=("filesystem" "memory")
    for server in "${critical_servers[@]}"; do
        if grep -q "\"$server\"" "$config_file"; then
            echo -e "${GREEN}✅ Found MCP server: $server${NC}"
        else
            echo -e "${YELLOW}⚠️  Missing MCP server: $server${NC}"
        fi
    done
}

# Function to create test workspace
create_test_workspace() {
    echo -e "\n${CYAN}Creating test workspace...${NC}"
    
    # Clean up any existing workspace
    if [ -d "$WORKSPACE_DIR" ]; then
        rm -rf "$WORKSPACE_DIR"
    fi
    
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    
    # Create separate directories for each instance
    for i in $(seq 1 $INSTANCE_COUNT); do
        mkdir -p "instance-$i"
        
        # Create a simple task file for each instance
        cat > "instance-$i/task.md" << EOF
# Task for Instance $i

## Objective
Create a simple function that returns "Hello from Instance $i"

## Requirements
1. Create a file named \`agent-$i.js\`
2. Export a function named \`greet\`
3. The function should return the greeting message
4. Add a comment with the instance number

## Success Criteria
- File exists at the correct location
- Function works correctly
- Code includes proper comments
EOF
    done
    
    echo -e "${GREEN}✅ Created workspace at: $WORKSPACE_DIR${NC}"
}

# Function to test single instance
test_single_instance() {
    local instance_num=$1
    local task_dir="$WORKSPACE_DIR/instance-$instance_num"
    
    echo -e "\n${BLUE}[Instance $instance_num] Starting test...${NC}"
    
    # Create a test script for the instance
    cat > "$task_dir/run-test.sh" << 'EOF'
#!/bin/bash
# This script will be executed by Claude Code

# Read the task
echo "Reading task..."
cat task.md

# Create the requested file
echo "Creating agent file..."
INSTANCE_NUM=$(basename $(pwd) | sed 's/instance-//')

cat > agent-$INSTANCE_NUM.js << EOJS
// Agent for Instance $INSTANCE_NUM
// Created by Claude Code with MCP support

/**
 * Greet function for instance $INSTANCE_NUM
 * @returns {string} Greeting message
 */
function greet() {
    return "Hello from Instance $INSTANCE_NUM";
}

// Export the function
module.exports = { greet };

// Test the function
console.log(greet());
EOJS

# Verify the file was created
if [ -f "agent-$INSTANCE_NUM.js" ]; then
    echo "✅ File created successfully"
    node agent-$INSTANCE_NUM.js
else
    echo "❌ File creation failed"
    exit 1
fi
EOF
    
    chmod +x "$task_dir/run-test.sh"
    
    echo -e "${GREEN}✅ Instance $instance_num ready${NC}"
}

# Function to simulate orchestrator
run_orchestrator() {
    echo -e "\n${YELLOW}🎭 Orchestrator: Distributing tasks...${NC}"
    
    # Create orchestration summary
    cat > "$WORKSPACE_DIR/orchestration-summary.md" << EOF
# Multi-Instance Orchestration Test

## Objective
Test that multiple Claude Code instances can:
1. Start independently
2. Load MCP servers
3. Complete assigned tasks
4. Work in parallel

## Task Distribution
- Instance 1: Create agent-1.js with greeting function
- Instance 2: Create agent-2.js with greeting function  
- Instance 3: Create agent-3.js with greeting function

## Expected Results
Each instance should create their respective files and verify functionality.
EOF
    
    echo -e "${GREEN}✅ Tasks distributed${NC}"
}

# Function to verify results
verify_results() {
    echo -e "\n${CYAN}Verifying results...${NC}"
    
    local success_count=0
    
    for i in $(seq 1 $INSTANCE_COUNT); do
        local agent_file="$WORKSPACE_DIR/instance-$i/agent-$i.js"
        
        if [ -f "$agent_file" ]; then
            echo -e "${GREEN}✅ Instance $i: File created${NC}"
            
            # Test the function
            cd "$WORKSPACE_DIR/instance-$i"
            local output=$(node "agent-$i.js" 2>&1)
            
            if [[ "$output" == *"Hello from Instance $i"* ]]; then
                echo -e "${GREEN}   Function works correctly${NC}"
                ((success_count++))
            else
                echo -e "${RED}   Function test failed${NC}"
            fi
            cd - > /dev/null
        else
            echo -e "${RED}❌ Instance $i: File not found${NC}"
        fi
    done
    
    echo -e "\n${BLUE}Summary:${NC}"
    echo -e "Successful instances: $success_count/$INSTANCE_COUNT"
    
    if [ $success_count -eq $INSTANCE_COUNT ]; then
        echo -e "${GREEN}🎉 All instances completed successfully!${NC}"
        return 0
    else
        echo -e "${RED}⚠️  Some instances failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Starting multi-instance test...${NC}"
    
    # Step 1: Check prerequisites
    check_claude_installation
    check_mcp_servers
    
    # Step 2: Create test workspace
    create_test_workspace
    
    # Step 3: Prepare instances
    for i in $(seq 1 $INSTANCE_COUNT); do
        test_single_instance $i
    done
    
    # Step 4: Run orchestrator
    run_orchestrator
    
    # Step 5: Show manual test instructions
    echo -e "\n${BLUE}📋 Manual Test Instructions:${NC}"
    echo "=============================="
    echo ""
    echo "Since Claude Code instances must be started manually, please:"
    echo ""
    echo "1. Open $INSTANCE_COUNT terminal windows"
    echo ""
    echo "2. In each terminal, navigate to the instance directory and start Claude:"
    echo "   Terminal 1: cd $WORKSPACE_DIR/instance-1 && claude"
    echo "   Terminal 2: cd $WORKSPACE_DIR/instance-2 && claude"
    echo "   Terminal 3: cd $WORKSPACE_DIR/instance-3 && claude"
    echo ""
    echo "3. In each Claude instance, run:"
    echo "   'Please read task.md and complete the task described'"
    echo ""
    echo "4. Wait for all instances to complete"
    echo ""
    echo "5. Run this command to verify results:"
    echo "   $0 --verify"
    echo ""
    
    # Save verification command
    cat > "$WORKSPACE_DIR/verify.sh" << EOF
#!/bin/bash
cd "$WORKSPACE_DIR"
$0 --verify
EOF
    chmod +x "$WORKSPACE_DIR/verify.sh"
}

# Handle verification mode
if [ "$1" == "--verify" ]; then
    cd "$WORKSPACE_DIR" 2>/dev/null || {
        echo -e "${RED}❌ Test workspace not found${NC}"
        echo "Please run the test first"
        exit 1
    }
    verify_results
    exit $?
fi

# Run main test
main

echo -e "\n${BLUE}Test workspace created at: $WORKSPACE_DIR${NC}"
echo -e "${YELLOW}Follow the manual instructions above to complete the test${NC}"