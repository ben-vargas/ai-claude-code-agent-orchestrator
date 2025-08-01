#!/bin/bash
# Install slash commands for Claude Code

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📝 Installing Slash Commands${NC}"
echo "==========================="
echo ""

# Check if running from repo root
if [ ! -d ".claude/slash-commands" ]; then
    echo -e "${RED}❌ Error: Not in repository root${NC}"
    echo "Please run from the Claude-Code-Agent-Orchestrator directory"
    exit 1
fi

# Create Claude slash commands directory
CLAUDE_SLASH_DIR="$HOME/.claude/slash-commands"
echo -e "${YELLOW}Creating slash commands directory...${NC}"
mkdir -p "$CLAUDE_SLASH_DIR"

# Copy slash commands
echo -e "${YELLOW}Installing slash commands...${NC}"

commands=(
    "alltools.md"
    "orchestrate.md"
    "orchestrate-quick.md"
    "orch.md"
)

installed=0
for cmd in "${commands[@]}"; do
    if [ -f ".claude/slash-commands/$cmd" ]; then
        cp ".claude/slash-commands/$cmd" "$CLAUDE_SLASH_DIR/"
        echo -e "${GREEN}✅ Installed: /$( basename "$cmd" .md)${NC}"
        ((installed++))
    else
        echo -e "${YELLOW}⚠️  Not found: $cmd${NC}"
    fi
done

echo ""
echo -e "${GREEN}✅ Installed $installed slash commands${NC}"
echo ""
echo -e "${BLUE}Available Commands:${NC}"
echo "  • /alltools         - Show all available tools and MCP servers"
echo "  • /orchestrate      - Full orchestration guide"
echo "  • /orchestrate-quick - Ready-to-use project templates"  
echo "  • /orch            - Quick orchestration shorthand"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "In Claude Code, type any slash command to use it."
echo "Example: /orchestrate"
echo ""

# Check if Claude is running
if pgrep -x "Claude" > /dev/null; then
    echo -e "${YELLOW}⚠️  Claude Code is running${NC}"
    echo "Slash commands will be available on next restart"
fi