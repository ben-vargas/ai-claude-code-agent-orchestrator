#!/bin/bash
# Monitor parallel orchestration test

echo "🎭 Parallel Orchestration Monitor"
echo "================================"
echo ""
echo "Starting monitoring tools..."
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Open monitoring in new terminal windows (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Terminal 1: Agent Monitor
    osascript -e 'tell app "Terminal" to do script "~/.claude/hooks/monitor-agents.sh"'
    
    # Terminal 2: SQLite Watch
    osascript -e 'tell app "Terminal" to do script "watch -n 2 \"echo \\\"=== Active Tasks ===\\\" && sqlite3 ~/.claude/agent-memory/agent-collaboration.db \\\"SELECT agent_id, status, title FROM agent_tasks WHERE datetime(created_at) > datetime(\\\\\\\"now\\\\\\\", \\\\\\\"-1 hour\\\\\\\") ORDER BY created_at DESC LIMIT 10;\\\"\""'
    
    # Terminal 3: Dashboard
    osascript -e 'tell app "Terminal" to do script "~/.claude/hooks/agent-dashboard.sh"'
    
    echo "✅ Opened 3 monitoring terminals"
    echo ""
fi

echo "📋 Manual Monitoring Commands:"
echo ""
echo "1. Check active agents:"
echo "   sqlite3 ~/.claude/agent-memory/agent-collaboration.db \"SELECT * FROM agent_tasks WHERE status='in_progress';\""
echo ""
echo "2. View coordination queue:"
echo "   sqlite3 ~/.claude/agent-memory/agent-collaboration.db \"SELECT * FROM agent_coordination_queue;\""
echo ""
echo "3. Check missing capabilities:"
echo "   sqlite3 ~/.claude/agent-memory/agent-collaboration.db \"SELECT * FROM missing_capabilities;\""
echo ""
echo "4. Monitor hook events:"
echo "   sqlite3 ~/.claude/agent-memory/agent-collaboration.db \"SELECT * FROM hook_tool_usage ORDER BY hook_timestamp DESC LIMIT 10;\""
echo ""
echo "5. Launch the test from:"
echo "   /Users/fred/parallel-orchestration-test/launch-all.sh"
echo ""
echo "Press Ctrl+C to exit monitoring"

# Keep script running
while true; do
    sleep 60
done