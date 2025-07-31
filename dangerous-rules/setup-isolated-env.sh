#!/bin/bash
# Setup script for isolated testing environment
# ⚠️ WARNING: Only use in disposable environments!

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}⚠️  DANGEROUS RULES SETUP ⚠️${NC}"
echo -e "${RED}================================${NC}"
echo ""
echo -e "${YELLOW}This script helps set up an ISOLATED environment for testing dangerous rules.${NC}"
echo -e "${YELLOW}DO NOT RUN THIS ON YOUR MAIN SYSTEM!${NC}"
echo ""
echo "You should only run this in:"
echo "  - A disposable virtual machine"
echo "  - A Docker container"
echo "  - A cloud workspace you can destroy"
echo ""
read -p "Are you in a disposable environment that can be destroyed? (type 'YES I UNDERSTAND'): " response

if [ "$response" != "YES I UNDERSTAND" ]; then
    echo -e "${RED}Setup cancelled. Please use a disposable environment.${NC}"
    exit 1
fi

# Create isolated Claude config
ISOLATED_DIR="$HOME/.claude-dangerous"
echo -e "${YELLOW}Creating isolated config at: $ISOLATED_DIR${NC}"
mkdir -p "$ISOLATED_DIR/rules"
mkdir -p "$ISOLATED_DIR/workspace"
mkdir -p "$ISOLATED_DIR/logs"

# Copy warning file
cat > "$ISOLATED_DIR/WARNING.txt" << 'EOF'
⚠️ DANGEROUS CONFIGURATION ACTIVE ⚠️

This Claude Code instance is running with DANGEROUS RULES that remove most safety checks.

ONLY use this in a disposable environment where data loss is acceptable.

To stop using dangerous rules:
1. Exit Claude Code
2. Run: rm -rf ~/.claude-dangerous
3. Unset CLAUDE_CONFIG_DIR environment variable
EOF

# Create launcher script
cat > "$ISOLATED_DIR/launch-dangerous-claude.sh" << 'EOF'
#!/bin/bash
# Launcher for Claude Code with dangerous rules

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}⚠️  LAUNCHING CLAUDE CODE WITH DANGEROUS RULES ⚠️${NC}"
echo ""
cat ~/.claude-dangerous/WARNING.txt
echo ""
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# Set isolated config directory
export CLAUDE_CONFIG_DIR="$HOME/.claude-dangerous"
export CLAUDE_WORKSPACE="$HOME/.claude-dangerous/workspace"
export CLAUDE_AUDIT_LOG="$HOME/.claude-dangerous/logs/audit.log"

# Launch Claude Code
echo "Starting Claude Code with dangerous rules..."
claude "$@"
EOF

chmod +x "$ISOLATED_DIR/launch-dangerous-claude.sh"

# Create rule selector
cat > "$ISOLATED_DIR/select-rules.sh" << 'EOF'
#!/bin/bash
# Select which dangerous rules to activate

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"

echo "Available dangerous rule sets:"
echo "1. permissive-dev-rules - For development automation"
echo "2. automation-rules - For CI/CD pipelines"
echo "3. research-rules - For data research"
echo "4. orchestration-rules - For multi-agent control"
echo ""
read -p "Select rule set (1-4): " choice

case $choice in
    1)
        cp ../dangerous-rules/permissive-dev-rules.json "$RULES_DIR/active-rules.json"
        echo "Activated: Permissive Development Rules"
        ;;
    2)
        cp ../dangerous-rules/automation-rules.json "$RULES_DIR/active-rules.json"
        echo "Activated: Automation Rules"
        ;;
    3)
        cp ../dangerous-rules/research-rules.json "$RULES_DIR/active-rules.json"
        echo "Activated: Research Rules"
        ;;
    4)
        cp ../dangerous-rules/orchestration-rules.json "$RULES_DIR/active-rules.json"
        echo "Activated: Orchestration Rules"
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo "Rules activated. Launch with: ~/.claude-dangerous/launch-dangerous-claude.sh"
EOF

chmod +x "$ISOLATED_DIR/select-rules.sh"

# Create monitoring script
cat > "$ISOLATED_DIR/monitor.sh" << 'EOF'
#!/bin/bash
# Monitor dangerous Claude Code activity

echo "Monitoring Claude Code activity..."
echo "Press Ctrl+C to stop"
echo ""

# Monitor in split panes if tmux available
if command -v tmux &> /dev/null; then
    tmux new-session -d -s claude-monitor
    tmux send-keys -t claude-monitor "watch -n 1 'find ~/.claude-dangerous/workspace -mmin -5 -type f 2>/dev/null | head -20'" C-m
    tmux split-window -h -t claude-monitor
    tmux send-keys -t claude-monitor "tail -f ~/.claude-dangerous/logs/audit.log 2>/dev/null" C-m
    tmux split-window -v -t claude-monitor
    tmux send-keys -t claude-monitor "htop -p \$(pgrep -f claude | tr '\n' ',')" C-m
    tmux attach -t claude-monitor
else
    # Fallback to simple monitoring
    watch -n 2 'echo "=== Recent File Changes ==="; \
                find ~/.claude-dangerous/workspace -mmin -5 -type f 2>/dev/null | head -10; \
                echo ""; \
                echo "=== Process Activity ==="; \
                ps aux | grep claude | grep -v grep'
fi
EOF

chmod +x "$ISOLATED_DIR/monitor.sh"

# Create cleanup script
cat > "$ISOLATED_DIR/emergency-cleanup.sh" << 'EOF'
#!/bin/bash
# Emergency cleanup script

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}🛑 EMERGENCY CLEANUP 🛑${NC}"
echo ""

# Kill all Claude processes
echo "Stopping all Claude Code processes..."
pkill -f claude || true

# Remove dangerous configuration
echo "Removing dangerous configuration..."
rm -rf ~/.claude-dangerous

# Unset environment variables
unset CLAUDE_CONFIG_DIR
unset CLAUDE_WORKSPACE
unset CLAUDE_AUDIT_LOG

echo ""
echo -e "${GREEN}✅ Cleanup complete${NC}"
echo "Dangerous rules have been removed."
EOF

chmod +x "$ISOLATED_DIR/emergency-cleanup.sh"

# Final instructions
echo ""
echo -e "${GREEN}✅ Isolated environment created${NC}"
echo ""
echo "Next steps:"
echo "1. cd $ISOLATED_DIR"
echo "2. Run: ./select-rules.sh"
echo "3. Launch with: ./launch-dangerous-claude.sh"
echo "4. Monitor with: ./monitor.sh"
echo ""
echo -e "${YELLOW}Emergency stop: ./emergency-cleanup.sh${NC}"
echo ""
echo -e "${RED}Remember: Only use in disposable environments!${NC}"