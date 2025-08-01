#!/bin/bash
# Update slash commands to be accessible by agents

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🤖 Updating Slash Commands for Agent Access${NC}"
echo "=========================================="
echo ""

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

# Initialize slash commands table
echo -e "${CYAN}Initializing slash commands registry...${NC}"

sqlite3 "$MEMORY_DB" << 'EOF'
-- Create slash commands table if not exists
CREATE TABLE IF NOT EXISTS slash_commands (
    command_name TEXT PRIMARY KEY,
    description TEXT,
    file_path TEXT,
    is_agent_accessible BOOLEAN DEFAULT FALSE,
    usage_example TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert or update slash commands
INSERT OR REPLACE INTO slash_commands (command_name, description, file_path, is_agent_accessible, usage_example)
VALUES 
    ('/alltools', 'Show all available tools and MCP servers', '.claude/slash-commands/alltools.md', 1, 
     'executeSlashCommand(agentId, "/alltools")'),
    
    ('/orchestrate', 'Full orchestration guide with examples', '.claude/slash-commands/orchestrate.md', 0,
     'For human use only - agents use Task tool directly'),
    
    ('/orchestrate-quick', 'Ready-to-use project templates', '.claude/slash-commands/orchestrate-quick.md', 0,
     'For human use only - agents use Task tool directly'),
    
    ('/orch', 'Quick orchestration shorthand', '.claude/slash-commands/orch.md', 0,
     'For human use only - agents use Task tool directly');

-- Show updated commands
SELECT 
    command_name as "Command",
    CASE is_agent_accessible 
        WHEN 1 THEN '✅ Yes' 
        ELSE '❌ No' 
    END as "Agent Access",
    description as "Description"
FROM slash_commands
ORDER BY command_name;
EOF

echo ""
echo -e "${GREEN}✅ Slash commands updated${NC}"
echo ""
echo -e "${YELLOW}Agent-Accessible Commands:${NC}"
echo "  • /alltools - Agents can discover their available tools"
echo ""
echo -e "${CYAN}Usage in Agent Code:${NC}"
echo '```javascript'
echo '// Agent can check available tools'
echo 'const tools = await executeSlashCommand(agentId, "/alltools");'
echo 'console.log(`I have access to ${tools.summary.totalCore} core tools`);'
echo '```'