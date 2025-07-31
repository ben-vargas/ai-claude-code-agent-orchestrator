#!/bin/bash
# Claude Code Agent Orchestrator Installation Script for macOS
# https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator

set -e

echo ""
echo "🎭 Claude Code Agent Orchestrator Installer for macOS"
echo "====================================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Warning: This script is optimized for macOS"
    echo "   Windows users: Please use windows/install.bat"
    echo "   Linux users: This script should work but is untested"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Claude directory exists
CLAUDE_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "❌ Error: Claude configuration directory not found at: $CLAUDE_DIR"
    echo "   Please ensure Claude Code is installed first"
    echo "   Download from: https://claude.ai/download"
    exit 1
fi

echo "✅ Found Claude directory at: $CLAUDE_DIR"
echo ""

# Create directories if they don't exist
echo "📁 Creating required directories..."
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/agent-workspaces"
mkdir -p "$CLAUDE_DIR/agent-archives"

# Check for existing installation
if [ -f "$CLAUDE_DIR/agents/orchestration-agent.md" ]; then
    echo "⚠️  Existing installation detected"
    read -p "   Overwrite existing agents? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Copy agent files
echo "📥 Installing agents..."
cp -r agents/* "$CLAUDE_DIR/agents/" 2>/dev/null || {
    echo "❌ Error: Failed to copy agent files"
    echo "   Are you running this from the repository root?"
    pwd
    exit 1
}

# Check if SQLite memory should be installed
echo ""
echo "💾 SQLite Memory Setup"
echo "─────────────────────"
echo "Would you like to install SQLite memory support?"
echo "This provides:"
echo "  • High-performance memory storage"
echo "  • Cross-agent memory sharing"
echo "  • Rich querying capabilities"
echo "  • Automatic fallback to filesystem"
echo ""
read -p "Install SQLite memory? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo "📦 Setting up SQLite memory..."
    
    # Create MCP servers directory
    mkdir -p "$CLAUDE_DIR/mcp-servers"
    
    # Copy SQLite memory server
    if [ -d "mcp-servers/sqlite-memory" ]; then
        cp -r mcp-servers/sqlite-memory "$CLAUDE_DIR/mcp-servers/"
        
        # Install dependencies
        echo "📥 Installing SQLite memory dependencies..."
        cd "$CLAUDE_DIR/mcp-servers/sqlite-memory"
        npm install --quiet
        cd - > /dev/null
        
        echo "✅ SQLite memory server installed"
        echo ""
        echo "⚠️  To enable SQLite memory, add this to your Claude MCP config:"
        echo "   ~/.claude/claude_desktop_config.json"
        echo ""
        echo '   "sqlite-memory": {'
        echo '     "command": "node",'
        echo '     "args": ["'$CLAUDE_DIR'/mcp-servers/sqlite-memory/index.js"],'
        echo '     "env": {'
        echo '       "MEMORY_DB_DIR": "'$CLAUDE_DIR'/agent-memory"'
        echo '     }'
        echo '   }'
        echo ""
    else
        echo "⚠️  SQLite memory server files not found in ./mcp-servers/sqlite-memory"
    fi
else
    echo "⏭️  Skipping SQLite memory setup"
fi

# Set proper permissions for macOS
chmod -R 755 "$CLAUDE_DIR/agents"

# Count installed agents
AGENT_COUNT=$(ls -1 "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l)
echo "✅ Installed $AGENT_COUNT agents"

# Verify key files
echo ""
echo "🔍 Verifying installation..."

if [ -f "$CLAUDE_DIR/agents/orchestration-agent.md" ]; then
    echo "   ✅ Orchestration agent installed"
else
    echo "   ❌ ERROR: Orchestration agent missing"
fi

if [ -f "$CLAUDE_DIR/agents/agent-registry.json" ]; then
    echo "   ✅ Agent registry installed"
else
    echo "   ❌ ERROR: Agent registry missing"
fi

if [ -f "$CLAUDE_DIR/agents/agent-output-schema.json" ]; then
    echo "   ✅ Output schema installed"
else
    echo "   ❌ ERROR: Output schema missing"
fi

# Check and setup MCP servers
echo ""
echo "🔌 MCP Server Setup"
echo "──────────────────"
echo "Checking MCP server configurations..."

# Run MCP server manager in auto mode
if [ -f "scripts/mcp-server-manager.sh" ]; then
    ./scripts/mcp-server-manager.sh --auto
else
    echo "⚠️  MCP server manager not found"
    echo "   Agents may not have access to all tools"
fi

# Check Claude Code process
if pgrep -x "Claude" > /dev/null; then
    echo ""
    echo "⚠️  Claude Code is currently running"
    echo "   Please restart it to load the new agents and MCP servers"
fi

# Installation complete
echo ""
echo "====================================================="
echo "🎉 Installation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Restart Claude Code (Cmd+Q then reopen)"
echo "2. Try: \"I want to build a SaaS product\""
echo "3. Watch agents collaborate in real-time!"
echo ""
echo "📁 Agent workspace: $CLAUDE_DIR/agent-workspaces/"
echo "📚 Documentation: https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator"
echo ""
echo "🔮 Coming Soon: MCP Integration!"
echo "   - Direct tool access without shell commands"
echo "   - Persistent memory across sessions"
echo "   - Enhanced performance and safety"
echo ""
echo "Happy orchestrating! 🎭✨"
echo ""