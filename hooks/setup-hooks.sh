#!/bin/bash
# Setup Claude Code hooks for agent tracking

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🪝 Setting up Claude Code Hooks${NC}"
echo "================================"
echo ""

# Check if running from hooks directory
HOOKS_DIR="$(dirname "$0")"
if [ ! -f "$HOOKS_DIR/tool-usage-hook.sh" ]; then
    echo -e "${RED}❌ Error: Not in hooks directory${NC}"
    echo "Please run from the hooks directory"
    exit 1
fi

# Configuration
CLAUDE_DIR="$HOME/.claude"
CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
MEMORY_DB="$CLAUDE_DIR/agent-memory/agent-collaboration.db"

# Create directories
echo -e "${CYAN}Creating directories...${NC}"
mkdir -p "$CLAUDE_HOOKS_DIR"
mkdir -p "$CLAUDE_DIR/agent-memory"
mkdir -p "$CLAUDE_DIR/agent-tracking-backup"
mkdir -p "$CLAUDE_DIR/agent-progress-backup"

# Initialize database with hook tables
echo -e "${CYAN}Initializing hook tables in SQLite...${NC}"
if [ -f "../agents/coordination-schema.sql" ]; then
    sqlite3 "$MEMORY_DB" < "../agents/coordination-schema.sql"
    echo -e "${GREEN}✅ Coordination schema created${NC}"
fi

# Create hook tables
sqlite3 "$MEMORY_DB" << 'EOF'
-- Tool usage tracking via hooks
CREATE TABLE IF NOT EXISTS hook_tool_usage (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    tool_parameters TEXT,
    execution_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_end TIMESTAMP,
    execution_duration_ms INTEGER,
    success BOOLEAN,
    error_message TEXT,
    result_summary TEXT,
    task_context TEXT,
    session_id TEXT,
    hook_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Progress tracking via hooks
CREATE TABLE IF NOT EXISTS hook_progress_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    event_type TEXT,
    task_id TEXT,
    progress_percentage INTEGER,
    milestone_name TEXT,
    milestone_details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT
);

-- Error tracking via hooks
CREATE TABLE IF NOT EXISTS hook_error_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    error_type TEXT,
    error_message TEXT,
    error_context TEXT,
    stack_trace TEXT,
    recovery_attempted BOOLEAN DEFAULT FALSE,
    recovery_successful BOOLEAN,
    impact_level TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT
);

-- Success tracking via hooks
CREATE TABLE IF NOT EXISTS hook_success_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    success_type TEXT,
    deliverable_name TEXT,
    quality_score REAL,
    performance_metrics TEXT,
    impact_assessment TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id TEXT
);

-- Session tracking
CREATE TABLE IF NOT EXISTS hook_agent_sessions (
    session_id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    total_tools_used INTEGER DEFAULT 0,
    total_errors INTEGER DEFAULT 0,
    total_successes INTEGER DEFAULT 0,
    session_metadata TEXT
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_hook_tool_usage_agent 
    ON hook_tool_usage(agent_id, execution_start);
CREATE INDEX IF NOT EXISTS idx_hook_progress_agent 
    ON hook_progress_events(agent_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_hook_errors_agent 
    ON hook_error_events(agent_id, error_type);
CREATE INDEX IF NOT EXISTS idx_hook_success_agent 
    ON hook_success_events(agent_id, success_type);
EOF

echo -e "${GREEN}✅ Hook tables created${NC}"

# Copy hook scripts
echo -e "${CYAN}Installing hook scripts...${NC}"
HOOKS=(
    "tool-usage-hook.sh"
    "progress-hook.sh"
    "error-recovery-hook.sh"
)

for hook in "${HOOKS[@]}"; do
    if [ -f "$HOOKS_DIR/$hook" ]; then
        cp "$HOOKS_DIR/$hook" "$CLAUDE_HOOKS_DIR/"
        chmod +x "$CLAUDE_HOOKS_DIR/$hook"
        echo -e "${GREEN}✅ Installed: $hook${NC}"
    else
        echo -e "${YELLOW}⚠️  Not found: $hook${NC}"
    fi
done

# Create hook configuration
echo -e "${CYAN}Creating hook configuration...${NC}"
cat > "$CLAUDE_HOOKS_DIR/config.json" << 'EOF'
{
  "hooks": [
    {
      "name": "tool-usage-tracking",
      "script": "tool-usage-hook.sh",
      "events": ["tool.before", "tool.after", "tool.error"],
      "enabled": true,
      "description": "Track all tool usage with timing and success metrics"
    },
    {
      "name": "progress-tracking",
      "script": "progress-hook.sh",
      "events": ["task.start", "milestone.reached", "deliverable.created", "task.complete", "task.blocked"],
      "enabled": true,
      "description": "Monitor agent progress and milestones"
    },
    {
      "name": "error-recovery",
      "script": "error-recovery-hook.sh",
      "events": ["error.captured", "error.recovered"],
      "enabled": true,
      "description": "Capture errors and attempt automatic recovery"
    }
  ],
  "global_settings": {
    "log_level": "info",
    "batch_interval": 60,
    "max_retries": 3,
    "storage_backend": "sqlite",
    "backup_to_files": true,
    "sensitive_data_masking": true
  }
}
EOF

echo -e "${GREEN}✅ Hook configuration created${NC}"

# Create test script
echo -e "${CYAN}Creating test script...${NC}"
cat > "$CLAUDE_HOOKS_DIR/test-hooks.sh" << 'EOF'
#!/bin/bash
# Test Claude Code hooks

echo "Testing Claude Code hooks..."
echo ""

# Test tool usage hook
echo "1. Testing tool usage hook:"
CLAUDE_AGENT_ID="test-agent" \
CLAUDE_TOOL_NAME="test-tool" \
CLAUDE_TOOL_PARAMS='{"action": "test"}' \
CLAUDE_TASK_ID="test-001" \
bash "$HOME/.claude/hooks/tool-usage-hook.sh" test

echo ""
echo "2. Testing progress hook:"
CLAUDE_AGENT_ID="test-agent" \
CLAUDE_TASK_ID="test-001" \
CLAUDE_TASK_TITLE="Test Task" \
CLAUDE_PROGRESS_EVENT="task.start" \
bash "$HOME/.claude/hooks/progress-hook.sh" test

echo ""
echo "3. Testing error hook:"
CLAUDE_AGENT_ID="test-agent" \
CLAUDE_ERROR_MESSAGE="command not found: git" \
CLAUDE_ERROR_TYPE="bash_error" \
bash "$HOME/.claude/hooks/error-recovery-hook.sh" test

echo ""
echo "✅ Hook tests completed!"
EOF

chmod +x "$CLAUDE_HOOKS_DIR/test-hooks.sh"
echo -e "${GREEN}✅ Test script created${NC}"

# Create monitoring script
echo -e "${CYAN}Creating monitoring script...${NC}"
cat > "$CLAUDE_HOOKS_DIR/monitor-agents.sh" << 'EOF'
#!/bin/bash
# Monitor agent activity in real-time

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

while true; do
    clear
    echo "=== Agent Activity Monitor ==="
    echo "$(date)"
    echo ""
    
    echo "📊 Active Sessions:"
    sqlite3 -column -header "$MEMORY_DB" "
        SELECT agent_id, session_id, 
               total_tools_used as tools,
               total_errors as errors,
               total_successes as success
        FROM hook_agent_sessions
        WHERE end_time IS NULL
        ORDER BY start_time DESC
        LIMIT 5;
    "
    
    echo ""
    echo "🛠️  Recent Tool Usage:"
    sqlite3 -column -header "$MEMORY_DB" "
        SELECT agent_id, tool_name, 
               CASE success WHEN 1 THEN '✓' ELSE '✗' END as ok,
               execution_duration_ms as ms
        FROM hook_tool_usage
        ORDER BY hook_timestamp DESC
        LIMIT 10;
    "
    
    echo ""
    echo "📈 Recent Progress:"
    sqlite3 -column -header "$MEMORY_DB" "
        SELECT agent_id, event_type, progress_percentage as '%'
        FROM hook_progress_events
        ORDER BY timestamp DESC
        LIMIT 5;
    "
    
    echo ""
    echo "❌ Recent Errors:"
    sqlite3 -column -header "$MEMORY_DB" "
        SELECT agent_id, error_type, 
               substr(error_message, 1, 40) || '...' as error
        FROM hook_error_events
        ORDER BY timestamp DESC
        LIMIT 5;
    "
    
    sleep 5
done
EOF

chmod +x "$CLAUDE_HOOKS_DIR/monitor-agents.sh"
echo -e "${GREEN}✅ Monitoring script created${NC}"

# Copy monitoring tools
echo -e "${CYAN}Installing monitoring tools...${NC}"
MONITORING_TOOLS=(
    "agent-dashboard.sh"
    "generate-daily-report.sh"
)

for tool in "${MONITORING_TOOLS[@]}"; do
    if [ -f "$HOOKS_DIR/$tool" ]; then
        cp "$HOOKS_DIR/$tool" "$CLAUDE_HOOKS_DIR/"
        chmod +x "$CLAUDE_HOOKS_DIR/$tool"
        echo -e "${GREEN}✅ Installed: $tool${NC}"
    fi
done

# Test hook installation
echo ""
echo -e "${CYAN}Testing hook installation...${NC}"
echo "=========================="
for script in tool-usage-hook.sh progress-hook.sh error-recovery-hook.sh; do
    if [ -f "$CLAUDE_HOOKS_DIR/$script" ]; then
        echo -n "Testing $script... "
        if bash "$CLAUDE_HOOKS_DIR/$script" test >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ (failed)${NC}"
        fi
    fi
done

# Slack configuration
echo ""
echo -e "${YELLOW}🔔 Slack Integration Setup${NC}"
echo "========================="
echo ""
echo "Would you like to configure Slack notifications? (y/n)"
read -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Copy Slack scripts
    echo -e "${CYAN}Installing Slack integration...${NC}"
    cp "$HOOKS_DIR/slack-notifier.sh" "$CLAUDE_HOOKS_DIR/"
    cp "$HOOKS_DIR/slack-integration.sh" "$CLAUDE_HOOKS_DIR/"
    chmod +x "$CLAUDE_HOOKS_DIR/slack-notifier.sh"
    chmod +x "$CLAUDE_HOOKS_DIR/slack-integration.sh"
    
    echo ""
    echo -e "${BLUE}To set up Slack notifications:${NC}"
    echo "1. Create a Slack webhook URL at:"
    echo "   https://api.slack.com/messaging/webhooks"
    echo ""
    echo "2. Run configuration:"
    echo "   $CLAUDE_HOOKS_DIR/slack-notifier.sh configure"
    echo ""
    echo "Would you like to configure Slack now? (y/n)"
    read -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$CLAUDE_HOOKS_DIR/slack-notifier.sh" configure
        
        echo ""
        echo -e "${CYAN}Testing Slack connection...${NC}"
        "$CLAUDE_HOOKS_DIR/slack-notifier.sh" test
    fi
else
    echo ""
    echo "Slack notifications skipped. You can enable them later by running:"
    echo "  $CLAUDE_HOOKS_DIR/slack-notifier.sh configure"
fi

# Show summary
echo ""
echo -e "${BLUE}📊 Hook Setup Summary${NC}"
echo "===================="
echo ""
echo -e "${GREEN}✅ Installed Components:${NC}"
echo "  • Hook scripts in: $CLAUDE_HOOKS_DIR"
echo "  • Database tables in: $MEMORY_DB"
echo "  • Backup directories created"
echo "  • Test and monitoring scripts"
if [ -f "$CLAUDE_HOOKS_DIR/slack-notifier.sh" ]; then
    echo "  • Slack integration available"
fi
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Test hooks: $CLAUDE_HOOKS_DIR/test-hooks.sh"
echo "2. Monitor agents: $CLAUDE_HOOKS_DIR/monitor-agents.sh"
echo "3. Advanced dashboard: $CLAUDE_HOOKS_DIR/agent-dashboard.sh"
if [ -f "$CLAUDE_HOOKS_DIR/slack-notifier.sh" ]; then
    echo "4. Configure Slack: $CLAUDE_HOOKS_DIR/slack-notifier.sh configure"
    echo "5. Start Slack monitor: $CLAUDE_HOOKS_DIR/slack-notifier.sh monitor"
fi
echo ""
echo -e "${CYAN}📝 Hook Events:${NC}"
echo "  • tool.before/after/error - Tool usage tracking"
echo "  • task.start/complete/blocked - Progress tracking"
echo "  • milestone.reached - Milestone tracking"
echo "  • deliverable.created - Success tracking"
echo "  • error.captured/recovered - Error handling"
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"