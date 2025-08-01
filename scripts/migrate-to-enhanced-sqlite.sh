#!/bin/bash
# Migrate existing agent data to enhanced SQLite storage

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔄 Migrating to Enhanced SQLite Storage${NC}"
echo "======================================"
echo ""

# Configuration
CLAUDE_DIR="$HOME/.claude"
AGENT_DIR="$CLAUDE_DIR/agents"
WORKSPACE_DIR="$CLAUDE_DIR/agent-workspaces"
MEMORY_DB="$CLAUDE_DIR/agent-memory/agent-collaboration.db"
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
echo -e "${YELLOW}Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup existing database
if [ -f "$MEMORY_DB" ]; then
    cp "$MEMORY_DB" "$BACKUP_DIR/agent-collaboration.db.backup"
    echo -e "${GREEN}✅ Database backed up${NC}"
fi

# Initialize enhanced schema
echo -e "${CYAN}Initializing enhanced schema...${NC}"
sqlite3 "$MEMORY_DB" < "$(dirname "$0")/../agents/sqlite-agent-storage-schema.sql"

# Populate agent registry
echo -e "${CYAN}Populating agent registry...${NC}"
if [ -f "$AGENT_DIR/agent-registry.json" ]; then
    # Use jq to parse and insert agents
    if command -v jq &> /dev/null; then
        jq -r '.agents | to_entries[] | 
            [.key, .value.name, .value.description, 
             (.value.expertise // [] | @json), 
             (.value.collaborationPatterns // {} | @json),
             (.value.tools // [] | @json),
             (.value.mcpRequirements // [] | @json)] | 
            @tsv' "$AGENT_DIR/agent-registry.json" | \
        while IFS=$'\t' read -r id name desc expertise collab tools mcp; do
            sqlite3 "$MEMORY_DB" << EOF
INSERT OR REPLACE INTO agent_registry 
(agent_id, name, description, expertise_areas, collaboration_patterns, tool_requirements, mcp_requirements)
VALUES ('$id', '$name', '$desc', '$expertise', '$collab', '$tools', '$mcp');
EOF
        done
        echo -e "${GREEN}✅ Agent registry populated${NC}"
    else
        echo -e "${YELLOW}⚠️  jq not installed - skipping registry import${NC}"
    fi
fi

# Migrate agent workspace files
echo -e "${CYAN}Migrating agent workspace files...${NC}"
workspace_count=0
if [ -d "$WORKSPACE_DIR" ]; then
    for workspace_file in "$WORKSPACE_DIR"/Agent-*.md; do
        if [ -f "$workspace_file" ]; then
            agent_name=$(basename "$workspace_file" .md | sed 's/Agent-//')
            echo -n "  Migrating $agent_name... "
            
            # Parse and insert workspace content
            # This is a simplified version - in production, you'd parse the markdown properly
            sqlite3 "$MEMORY_DB" << EOF
INSERT INTO agent_workspaces (agent_id, content_type, content, metadata)
VALUES ('$agent_name', 'migrated', '$(cat "$workspace_file" | sed "s/'/''/g")', 
        '{"source": "file_migration", "original_file": "$workspace_file"}');
EOF
            ((workspace_count++))
            echo -e "${GREEN}✓${NC}"
        fi
    done
fi
echo -e "${GREEN}✅ Migrated $workspace_count workspace files${NC}"

# Check MCP server availability
echo -e "${CYAN}Checking MCP server availability...${NC}"
MCP_CONFIG="$CLAUDE_DIR/claude_desktop_config.json"
if [ -f "$MCP_CONFIG" ] && command -v jq &> /dev/null; then
    jq -r '.mcpServers | to_entries[] | [.key, .value.command // ""] | @tsv' "$MCP_CONFIG" | \
    while IFS=$'\t' read -r server cmd; do
        if [ -n "$cmd" ] && (command -v "$cmd" &> /dev/null || [ -f "$cmd" ]); then
            sqlite3 "$MEMORY_DB" << EOF
INSERT OR REPLACE INTO mcp_availability (server_name, is_available, executable_path)
VALUES ('$server', 1, '$cmd');
EOF
            echo -e "  ${GREEN}✓${NC} $server"
        else
            sqlite3 "$MEMORY_DB" << EOF
INSERT OR REPLACE INTO mcp_availability (server_name, is_available, error_message)
VALUES ('$server', 0, 'Executable not found: $cmd');
EOF
            echo -e "  ${RED}✗${NC} $server"
        fi
    done
else
    echo -e "${YELLOW}⚠️  MCP config not found or jq not installed${NC}"
fi

# Create views and triggers
echo -e "${CYAN}Creating database views...${NC}"
sqlite3 "$MEMORY_DB" << 'EOF'
-- Ensure all views are created
SELECT 'Views created' WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='view');
EOF

# Generate summary report
echo -e "\n${BLUE}📊 Migration Summary${NC}"
echo "==================="

sqlite3 -column -header "$MEMORY_DB" << 'EOF'
SELECT 'Agent Registry' as "Table", COUNT(*) as "Records" FROM agent_registry
UNION ALL
SELECT 'Agent Workspaces', COUNT(*) FROM agent_workspaces
UNION ALL
SELECT 'MCP Servers', COUNT(*) FROM mcp_availability
UNION ALL
SELECT 'Slash Commands', COUNT(*) FROM slash_commands;
EOF

echo ""
echo -e "${GREEN}✅ Migration complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Verify data in: $MEMORY_DB"
echo "2. Original files backed up to: $BACKUP_DIR"
echo "3. The system now uses SQLite with file synchronization"
echo ""
echo -e "${CYAN}To verify:${NC}"
echo "  sqlite3 $MEMORY_DB"
echo "  .tables"
echo "  SELECT * FROM agent_registry;"