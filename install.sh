#!/bin/bash

# Claude Code Agent Orchestrator Installation Script
# https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator

set -e

echo "🎭 Claude Code Agent Orchestrator Installer"
echo "=========================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    CLAUDE_DIR="$HOME/.claude"
    echo "✓ Detected macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CLAUDE_DIR="$HOME/.claude"
    echo "✓ Detected Linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    CLAUDE_DIR="$USERPROFILE/.claude"
    echo "✓ Detected Windows"
else
    echo "⚠️  Unknown OS: $OSTYPE"
    echo "Please install manually following the README instructions"
    exit 1
fi

# Check if Claude directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "⚠️  Claude configuration directory not found at: $CLAUDE_DIR"
    echo "Please ensure Claude Code is installed first"
    exit 1
fi

echo "📁 Claude directory found at: $CLAUDE_DIR"
echo ""

# Create directories if they don't exist
echo "Creating required directories..."
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/agent-workspaces"
mkdir -p "$CLAUDE_DIR/agent-archives"

# Copy agent files
echo "📦 Installing agents..."
cp -r agents/* "$CLAUDE_DIR/agents/" 2>/dev/null || {
    echo "⚠️  No agents directory found. Are you running this from the repository root?"
    exit 1
}

# Count installed agents
AGENT_COUNT=$(ls -1 "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l)
echo "✓ Installed $AGENT_COUNT agents"

# Verify key files
echo ""
echo "🔍 Verifying installation..."

if [ -f "$CLAUDE_DIR/agents/orchestration-agent.md" ]; then
    echo "✓ Orchestration agent installed"
else
    echo "✗ Orchestration agent missing"
fi

if [ -f "$CLAUDE_DIR/agents/agent-registry.json" ]; then
    echo "✓ Agent registry installed"
else
    echo "✗ Agent registry missing"
fi

if [ -f "$CLAUDE_DIR/agents/agent-output-schema.json" ]; then
    echo "✓ Output schema installed"
else
    echo "✗ Output schema missing"
fi

# Installation complete
echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code to load the new agents"
echo "2. Try: 'I want to build a SaaS product' to see orchestration in action"
echo "3. Check ~/.claude/agent-workspaces/ for agent activity logs"
echo ""
echo "📚 Documentation:"
echo "- Quick Start: $CLAUDE_DIR/agents/AGENT-QUICK-START.md"
echo "- Full Guide: $CLAUDE_DIR/agents/AGENT-COMPLETE-GUIDE.md"
echo ""
echo "Happy orchestrating! 🚀"