#!/bin/bash
# Claude Code Agent Orchestrator - Memory System Quick Start
# This script sets up the basic memory infrastructure

set -e

echo "🧠 Claude Code Agent Memory System Setup"
echo "========================================"
echo ""

# Check if Claude directory exists
CLAUDE_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "❌ Error: Claude directory not found at: $CLAUDE_DIR"
    echo "   Please ensure Claude Code is installed first"
    exit 1
fi

echo "✅ Found Claude directory at: $CLAUDE_DIR"

# Create memory directories
echo ""
echo "📁 Creating memory directories..."
mkdir -p "$CLAUDE_DIR/agent-memory"
mkdir -p "$CLAUDE_DIR/agent-memory/sessions"
mkdir -p "$CLAUDE_DIR/agent-memory/extended"
mkdir -p "$CLAUDE_DIR/memory-services"

# Step 1: Set up Memory Keeper (SQLite-based)
echo ""
echo "📦 Setting up Memory Keeper..."
cd "$CLAUDE_DIR/memory-services"

# Create a simple memory keeper implementation
cat > memory-keeper.js << 'EOF'
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

class MemoryKeeper {
  constructor(dbPath) {
    this.db = new Database(dbPath);
    this.initDatabase();
  }

  initDatabase() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY,
        agent_id TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        timestamp INTEGER DEFAULT (strftime('%s', 'now')),
        importance INTEGER DEFAULT 5,
        tags TEXT,
        UNIQUE(agent_id, key)
      );
      
      CREATE INDEX IF NOT EXISTS idx_agent_key ON memories(agent_id, key);
      CREATE INDEX IF NOT EXISTS idx_timestamp ON memories(timestamp DESC);
      CREATE INDEX IF NOT EXISTS idx_importance ON memories(importance DESC);
    `);
  }

  store(agentId, key, value, importance = 5, tags = []) {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO memories (id, agent_id, key, value, importance, tags)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const id = `${agentId}-${key}-${Date.now()}`;
    stmt.run(id, agentId, key, JSON.stringify(value), importance, JSON.stringify(tags));
    return id;
  }

  retrieve(agentId, key = null) {
    if (key) {
      const stmt = this.db.prepare('SELECT * FROM memories WHERE agent_id = ? AND key = ?');
      const result = stmt.get(agentId, key);
      return result ? { ...result, value: JSON.parse(result.value), tags: JSON.parse(result.tags) } : null;
    } else {
      const stmt = this.db.prepare('SELECT * FROM memories WHERE agent_id = ? ORDER BY timestamp DESC LIMIT 100');
      const results = stmt.all(agentId);
      return results.map(r => ({ ...r, value: JSON.parse(r.value), tags: JSON.parse(r.tags) }));
    }
  }

  search(agentId, query, minImportance = 0) {
    const stmt = this.db.prepare(`
      SELECT * FROM memories 
      WHERE agent_id = ? 
      AND importance >= ?
      AND (key LIKE ? OR value LIKE ?)
      ORDER BY importance DESC, timestamp DESC
      LIMIT 50
    `);
    
    const searchPattern = `%${query}%`;
    const results = stmt.all(agentId, minImportance, searchPattern, searchPattern);
    return results.map(r => ({ ...r, value: JSON.parse(r.value), tags: JSON.parse(r.tags) }));
  }

  updateImportance(id, newImportance) {
    const stmt = this.db.prepare('UPDATE memories SET importance = ? WHERE id = ?');
    stmt.run(newImportance, id);
  }

  getStats(agentId = null) {
    if (agentId) {
      const stmt = this.db.prepare('SELECT COUNT(*) as count, AVG(importance) as avg_importance FROM memories WHERE agent_id = ?');
      return stmt.get(agentId);
    } else {
      const stmt = this.db.prepare('SELECT agent_id, COUNT(*) as count, AVG(importance) as avg_importance FROM memories GROUP BY agent_id');
      return stmt.all();
    }
  }
}

// MCP Server wrapper
if (require.main === module) {
  const dbPath = process.env.MEMORY_DB_PATH || path.join(__dirname, 'memory.db');
  const keeper = new MemoryKeeper(dbPath);
  
  // Simple JSON-RPC server for MCP
  process.stdin.on('data', (data) => {
    try {
      const request = JSON.parse(data.toString());
      let result;
      
      switch (request.method) {
        case 'store':
          result = keeper.store(request.params.agent_id, request.params.key, request.params.value, request.params.importance, request.params.tags);
          break;
        case 'retrieve':
          result = keeper.retrieve(request.params.agent_id, request.params.key);
          break;
        case 'search':
          result = keeper.search(request.params.agent_id, request.params.query, request.params.min_importance);
          break;
        case 'update_importance':
          result = keeper.updateImportance(request.params.id, request.params.importance);
          break;
        case 'stats':
          result = keeper.getStats(request.params.agent_id);
          break;
        default:
          result = { error: 'Unknown method' };
      }
      
      process.stdout.write(JSON.stringify({ id: request.id, result }) + '\n');
    } catch (error) {
      process.stdout.write(JSON.stringify({ error: error.message }) + '\n');
    }
  });
}

module.exports = MemoryKeeper;
EOF

# Create package.json
cat > package.json << 'EOF'
{
  "name": "claude-agent-memory",
  "version": "1.0.0",
  "description": "Memory system for Claude Code Agent Orchestrator",
  "main": "memory-keeper.js",
  "dependencies": {
    "better-sqlite3": "^9.0.0"
  }
}
EOF

# Install dependencies
echo "📥 Installing dependencies..."
npm install

# Step 2: Create Memory Integration for Agents
echo ""
echo "🔧 Creating memory integration module..."

cat > "$CLAUDE_DIR/agents/memory-integration.md" << 'EOF'
---
name: memory-integration
description: Memory system integration for all agents
---

## Memory System Usage Guide

### Storing Memories

When you complete a task or learn something important:
```javascript
// Store a memory with the Memory Keeper
{
  "method": "store",
  "params": {
    "agent_id": "your-agent-name",
    "key": "unique-key-for-this-memory",
    "value": {
      "content": "What you learned or did",
      "context": "Additional context",
      "related_tasks": ["task-id-1", "task-id-2"]
    },
    "importance": 8, // 1-10 scale
    "tags": ["learning", "api-design", "successful-pattern"]
  }
}
```

### Retrieving Memories

Before starting a task, retrieve relevant context:
```javascript
// Get specific memory
{
  "method": "retrieve",
  "params": {
    "agent_id": "your-agent-name",
    "key": "specific-memory-key"
  }
}

// Search memories
{
  "method": "search",
  "params": {
    "agent_id": "your-agent-name",
    "query": "api authentication",
    "min_importance": 6
  }
}
```

### Memory Best Practices

1. **What to Store**:
   - Successful solution patterns
   - Error resolutions
   - Important decisions and rationales
   - Cross-agent collaboration outcomes
   - Performance optimizations discovered

2. **Importance Scoring**:
   - 1-3: Routine information
   - 4-6: Useful patterns and learnings
   - 7-8: Important insights and solutions
   - 9-10: Critical knowledge and breakthroughs

3. **Key Naming Convention**:
   - Format: `{category}-{subcategory}-{specific-identifier}`
   - Examples:
     - `api-auth-jwt-implementation`
     - `database-optimization-index-strategy`
     - `collaboration-frontend-api-contract`

4. **Cross-Agent Memory Sharing**:
   - Tag memories that other agents might need
   - Reference other agents in the value content
   - Use consistent terminology across agents
EOF

# Step 3: Create Session Manager
echo ""
echo "📝 Creating session management..."

cat > "$CLAUDE_DIR/memory-services/session-manager.js" << 'EOF'
const fs = require('fs').promises;
const path = require('path');

class SessionManager {
  constructor(basePath) {
    this.basePath = basePath;
  }

  async createSession(agentId) {
    const sessionId = `${agentId}-${Date.now()}`;
    const sessionPath = path.join(this.basePath, sessionId);
    
    await fs.mkdir(sessionPath, { recursive: true });
    
    const metadata = {
      sessionId,
      agentId,
      startTime: new Date().toISOString(),
      lastActive: new Date().toISOString(),
      memories: []
    };
    
    await fs.writeFile(
      path.join(sessionPath, 'metadata.json'),
      JSON.stringify(metadata, null, 2)
    );
    
    return sessionId;
  }

  async getRecentSessions(agentId, limit = 5) {
    const sessions = await fs.readdir(this.basePath);
    const agentSessions = [];
    
    for (const session of sessions) {
      if (session.startsWith(agentId)) {
        const metadataPath = path.join(this.basePath, session, 'metadata.json');
        try {
          const metadata = JSON.parse(await fs.readFile(metadataPath, 'utf8'));
          agentSessions.push(metadata);
        } catch (error) {
          console.error(`Error reading session ${session}:`, error);
        }
      }
    }
    
    return agentSessions
      .sort((a, b) => new Date(b.lastActive) - new Date(a.lastActive))
      .slice(0, limit);
  }
}

module.exports = SessionManager;
EOF

# Step 4: Create example configuration
echo ""
echo "⚙️  Creating example configuration..."

cat > "$CLAUDE_DIR/agent-memory/config.json" << 'EOF'
{
  "memory": {
    "enabled": true,
    "defaultImportance": 5,
    "retentionDays": 90,
    "maxMemoriesPerAgent": 10000,
    "pruningEnabled": true,
    "pruningInterval": "weekly"
  },
  "agents": {
    "backend-expert": {
      "memoryEnabled": true,
      "autoTags": ["backend", "api", "architecture"],
      "importanceBoost": 1
    },
    "frontend-expert": {
      "memoryEnabled": true,
      "autoTags": ["frontend", "ui", "react"],
      "importanceBoost": 0
    },
    "orchestration-agent": {
      "memoryEnabled": true,
      "autoTags": ["orchestration", "workflow", "coordination"],
      "importanceBoost": 2,
      "crossAgentAccess": true
    }
  },
  "sharing": {
    "enableCrossAgentMemory": true,
    "sharedTags": ["learning", "error", "success", "pattern"],
    "minimumImportanceForSharing": 7
  }
}
EOF

# Step 5: Update MCP configuration
echo ""
echo "🔗 Updating Claude MCP configuration..."

MCP_CONFIG="$CLAUDE_DIR/claude_desktop_config.json"
if [ -f "$MCP_CONFIG" ]; then
    echo "   ℹ️  MCP config exists. Please manually add the memory-keeper server:"
    echo ""
    echo '  "memory-keeper": {'
    echo '    "command": "node",'
    echo '    "args": ["'$CLAUDE_DIR'/memory-services/memory-keeper.js"],'
    echo '    "env": {'
    echo '      "MEMORY_DB_PATH": "'$CLAUDE_DIR'/agent-memory/memory.db"'
    echo '    }'
    echo '  }'
else
    echo "   ⚠️  MCP config not found. Creating example at: $MCP_CONFIG.example"
    cat > "$MCP_CONFIG.example" << EOF
{
  "mcpServers": {
    "memory-keeper": {
      "command": "node",
      "args": ["$CLAUDE_DIR/memory-services/memory-keeper.js"],
      "env": {
        "MEMORY_DB_PATH": "$CLAUDE_DIR/agent-memory/memory.db"
      }
    }
  }
}
EOF
fi

# Step 6: Create test script
echo ""
echo "🧪 Creating memory test script..."

cat > "$CLAUDE_DIR/agent-memory/test-memory.js" << 'EOF'
const MemoryKeeper = require('../memory-services/memory-keeper');
const SessionManager = require('../memory-services/session-manager');
const path = require('path');

async function testMemorySystem() {
  console.log('Testing Memory System...\n');
  
  // Initialize
  const dbPath = path.join(__dirname, 'test-memory.db');
  const memory = new MemoryKeeper(dbPath);
  const sessions = new SessionManager(path.join(__dirname, 'sessions'));
  
  // Test 1: Store memories
  console.log('1. Storing memories...');
  memory.store('backend-expert', 'api-pattern-rest', {
    pattern: 'RESTful API Design',
    details: 'Use consistent naming, proper HTTP verbs',
    example: 'GET /api/users/:id'
  }, 8, ['api', 'pattern', 'rest']);
  
  memory.store('backend-expert', 'error-handling-strategy', {
    strategy: 'Global error handler with custom error classes',
    implementation: 'Centralized error middleware'
  }, 7, ['error-handling', 'pattern']);
  
  // Test 2: Retrieve memories
  console.log('\n2. Retrieving memories...');
  const apiPattern = memory.retrieve('backend-expert', 'api-pattern-rest');
  console.log('Retrieved:', apiPattern);
  
  // Test 3: Search memories
  console.log('\n3. Searching memories...');
  const searchResults = memory.search('backend-expert', 'pattern', 6);
  console.log('Search results:', searchResults.length, 'memories found');
  
  // Test 4: Get statistics
  console.log('\n4. Memory statistics...');
  const stats = memory.getStats('backend-expert');
  console.log('Stats:', stats);
  
  // Test 5: Session management
  console.log('\n5. Creating session...');
  const sessionId = await sessions.createSession('backend-expert');
  console.log('Session created:', sessionId);
  
  console.log('\n✅ Memory system test complete!');
}

testMemorySystem().catch(console.error);
EOF

# Run the test
echo ""
echo "🧪 Running memory system test..."
cd "$CLAUDE_DIR/agent-memory"
node test-memory.js

# Final instructions
echo ""
echo "====================================================="
echo "✅ Memory system setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Restart Claude Code to load the memory system"
echo "2. The memory-keeper MCP server is ready to use"
echo "3. All agents can now store and retrieve memories"
echo ""
echo "📚 Quick usage in Claude Code:"
echo '   "Store this API pattern as important memory"'
echo '   "What do I remember about authentication?"'
echo '   "Retrieve memories about database optimization"'
echo ""
echo "📁 Memory locations:"
echo "   Database: $CLAUDE_DIR/agent-memory/memory.db"
echo "   Sessions: $CLAUDE_DIR/agent-memory/sessions/"
echo "   Config: $CLAUDE_DIR/agent-memory/config.json"
echo ""
echo "🧠 Memory is now persistent across Claude sessions!"
echo ""