# Memory Implementation Guide for Claude Code Agent Orchestrator

This guide provides a step-by-step approach to implementing a robust memory system for the Claude Code Agent Orchestrator.

## Overview

The memory system consists of four integrated components:
1. **Memory Keeper (SQLite)** - Fast key-value storage for recent interactions
2. **Extended Memory Server** - Importance-based long-term recall
3. **Unified Memory Layer** - Abstraction layer for all agents
4. **Cross-Session Persistence** - Continuity across Claude sessions

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Agent System                  │
├─────────────────────────────────────────────────────────────┤
│                    Unified Memory Layer API                  │
├─────────────────────────────────────────────────────────────┤
│ Memory     │ Extended Memory │ Vector DB │ Thread           │
│ Keeper     │ Server          │ (Future)  │ Continuity       │
│ (SQLite)   │ (Importance)    │           │                  │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Memory Keeper Integration (Weeks 1-2)

### 1.1 Install Memory Keeper MCP Server

```bash
# Clone the Memory Keeper repository
cd ~/.claude/
git clone https://github.com/coleam00/mcp-memory-service memory-keeper
cd memory-keeper
npm install
npm run build
```

### 1.2 Configure MCP Server in Claude

Add to Claude's MCP configuration:

```json
{
  "mcpServers": {
    "memory-keeper": {
      "command": "node",
      "args": ["~/.claude/memory-keeper/dist/index.js"],
      "env": {
        "MEMORY_DB_PATH": "~/.claude/agent-memory/memory.db"
      }
    }
  }
}
```

### 1.3 Create Memory Wrapper for Agents

Create `agents/memory-interface.md`:

```markdown
---
name: memory-interface
description: Internal memory management interface for all agents
---

## Memory Operations

### Store Memory
```json
{
  "operation": "store",
  "agent": "agent-name",
  "key": "unique-key",
  "value": {
    "content": "memory-content",
    "timestamp": "ISO-8601",
    "importance": 0-10,
    "tags": ["tag1", "tag2"]
  }
}
```

### Retrieve Memory
```json
{
  "operation": "retrieve",
  "agent": "agent-name",
  "query": "search-query",
  "filters": {
    "timeRange": "last-7-days",
    "minImportance": 5,
    "tags": ["specific-tag"]
  }
}
```

### Update Importance
```json
{
  "operation": "update-importance",
  "key": "memory-key",
  "importance": 8,
  "reason": "Referenced multiple times"
}
```
```

## Phase 2: Extended Memory Server (Weeks 3-4)

### 2.1 Set Up Extended Memory Server

```bash
# Clone Extended Memory Server
cd ~/.claude/
git clone https://github.com/exampleuser/extended-memory-server
cd extended-memory-server
npm install
npm run build
```

### 2.2 Configure Importance-Based Recall

Create `~/.claude/extended-memory/config.json`:

```json
{
  "importanceThreshold": 7,
  "decayRate": 0.1,
  "recallStrategies": {
    "similarity": 0.4,
    "recency": 0.3,
    "frequency": 0.3
  },
  "maxMemorySize": 10000,
  "pruningStrategy": "importance-based"
}
```

### 2.3 Add to MCP Configuration

```json
{
  "mcpServers": {
    "extended-memory": {
      "command": "node",
      "args": ["~/.claude/extended-memory-server/dist/index.js"],
      "env": {
        "CONFIG_PATH": "~/.claude/extended-memory/config.json",
        "DATA_PATH": "~/.claude/agent-memory/extended/"
      }
    }
  }
}
```

## Phase 3: Unified Memory Layer (Weeks 5-6)

### 3.1 Create Memory Orchestrator Agent

Create `agents/memory-orchestrator.md`:

```markdown
---
name: memory-orchestrator
description: Manages unified memory operations across all storage backends
---

You are the Memory Orchestrator, responsible for managing memory operations across all agents.

## Memory Strategy

### Storage Rules
1. **Immediate Storage** (Memory Keeper):
   - All agent interactions
   - Task outcomes
   - Decision rationales
   - Error logs

2. **Long-term Storage** (Extended Memory):
   - Important insights (importance > 7)
   - Successful patterns
   - Cross-agent learnings
   - Project milestones

3. **Cross-Reference Storage**:
   - Agent collaboration outcomes
   - Dependency relationships
   - Performance metrics

### Retrieval Strategy
1. Check Memory Keeper for recent (< 7 days)
2. Query Extended Memory for important historical data
3. Aggregate and rank results by relevance
4. Return formatted memory context

## Memory Schema

```json
{
  "memoryId": "uuid",
  "agentId": "agent-name",
  "timestamp": "ISO-8601",
  "type": "interaction|learning|error|milestone",
  "content": {
    "summary": "brief description",
    "details": "full content",
    "relatedAgents": ["agent1", "agent2"],
    "taskId": "task-uuid"
  },
  "metadata": {
    "importance": 0-10,
    "accessCount": 0,
    "lastAccessed": "ISO-8601",
    "tags": ["tag1", "tag2"],
    "relationships": ["memory-id-1", "memory-id-2"]
  }
}
```
```

### 3.2 Update Agent Registry

Add memory capabilities to `agents/agent-registry.json`:

```json
{
  "agents": [
    {
      "name": "backend-expert",
      "memoryConfig": {
        "enabled": true,
        "retentionDays": 30,
        "importanceThreshold": 6,
        "autoTag": ["api", "backend", "architecture"]
      }
    }
  ],
  "memoryIntegration": {
    "defaultRetention": 30,
    "crossAgentSharing": true,
    "memoryOrchestrator": "memory-orchestrator"
  }
}
```

### 3.3 Implement Memory Hooks

Create `agents/memory-hooks.json`:

```json
{
  "hooks": {
    "beforeTaskStart": {
      "action": "retrieve-context",
      "params": {
        "lookback": "related-tasks",
        "includeCollaborators": true
      }
    },
    "afterTaskComplete": {
      "action": "store-outcome",
      "params": {
        "includeMetrics": true,
        "calculateImportance": true
      }
    },
    "onError": {
      "action": "store-error-pattern",
      "params": {
        "importance": 8,
        "shareWithAgents": ["qa-test-engineer", "devops-sre-expert"]
      }
    },
    "onInsight": {
      "action": "store-learning",
      "params": {
        "importance": 9,
        "broadcast": true
      }
    }
  }
}
```

## Phase 4: Cross-Session Persistence (Weeks 7-8)

### 4.1 Session Management

Create `~/.claude/agent-memory/session-manager.js`:

```javascript
const fs = require('fs');
const path = require('path');

class SessionManager {
  constructor(basePath = '~/.claude/agent-memory/sessions') {
    this.basePath = basePath;
    this.currentSession = null;
  }

  async startSession(agentName) {
    const sessionId = `${agentName}-${Date.now()}`;
    const sessionPath = path.join(this.basePath, sessionId);
    
    // Create session directory
    await fs.promises.mkdir(sessionPath, { recursive: true });
    
    // Initialize session metadata
    const metadata = {
      sessionId,
      agentName,
      startTime: new Date().toISOString(),
      lastActive: new Date().toISOString(),
      memoryKeys: []
    };
    
    await fs.promises.writeFile(
      path.join(sessionPath, 'metadata.json'),
      JSON.stringify(metadata, null, 2)
    );
    
    this.currentSession = sessionId;
    return sessionId;
  }

  async continueSession(sessionId) {
    const metadataPath = path.join(this.basePath, sessionId, 'metadata.json');
    const metadata = JSON.parse(await fs.promises.readFile(metadataPath, 'utf8'));
    
    // Update last active time
    metadata.lastActive = new Date().toISOString();
    await fs.promises.writeFile(metadataPath, JSON.stringify(metadata, null, 2));
    
    this.currentSession = sessionId;
    return metadata;
  }

  async listSessions(agentName = null) {
    const sessions = await fs.promises.readdir(this.basePath);
    const sessionList = [];
    
    for (const session of sessions) {
      const metadataPath = path.join(this.basePath, session, 'metadata.json');
      try {
        const metadata = JSON.parse(await fs.promises.readFile(metadataPath, 'utf8'));
        if (!agentName || metadata.agentName === agentName) {
          sessionList.push(metadata);
        }
      } catch (error) {
        console.error(`Error reading session ${session}:`, error);
      }
    }
    
    return sessionList.sort((a, b) => 
      new Date(b.lastActive) - new Date(a.lastActive)
    );
  }
}

module.exports = SessionManager;
```

### 4.2 Memory Persistence Layer

Create `~/.claude/agent-memory/persistence.js`:

```javascript
const sqlite3 = require('sqlite3').verbose();
const { promisify } = require('util');

class MemoryPersistence {
  constructor(dbPath = '~/.claude/agent-memory/unified-memory.db') {
    this.db = new sqlite3.Database(dbPath);
    this.run = promisify(this.db.run.bind(this.db));
    this.get = promisify(this.db.get.bind(this.db));
    this.all = promisify(this.db.all.bind(this.db));
    
    this.initializeDatabase();
  }

  async initializeDatabase() {
    await this.run(`
      CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY,
        agent_id TEXT NOT NULL,
        session_id TEXT,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        importance INTEGER DEFAULT 5,
        access_count INTEGER DEFAULT 0,
        last_accessed TEXT,
        tags TEXT,
        related_memories TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    `);

    await this.run(`
      CREATE INDEX IF NOT EXISTS idx_agent_timestamp 
      ON memories(agent_id, timestamp DESC)
    `);

    await this.run(`
      CREATE INDEX IF NOT EXISTS idx_importance 
      ON memories(importance DESC)
    `);

    await this.run(`
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        agent_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        last_active TEXT NOT NULL,
        context TEXT
      )
    `);
  }

  async storeMemory(memory) {
    const { id, agentId, sessionId, timestamp, type, content, importance, tags, relatedMemories } = memory;
    
    await this.run(`
      INSERT OR REPLACE INTO memories 
      (id, agent_id, session_id, timestamp, type, content, importance, tags, related_memories)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      id,
      agentId,
      sessionId,
      timestamp,
      type,
      JSON.stringify(content),
      importance,
      JSON.stringify(tags || []),
      JSON.stringify(relatedMemories || [])
    ]);
  }

  async retrieveMemories(agentId, options = {}) {
    const { 
      limit = 100, 
      minImportance = 0, 
      type = null, 
      sessionId = null,
      timeRange = null 
    } = options;

    let query = `
      SELECT * FROM memories 
      WHERE agent_id = ? AND importance >= ?
    `;
    const params = [agentId, minImportance];

    if (type) {
      query += ' AND type = ?';
      params.push(type);
    }

    if (sessionId) {
      query += ' AND session_id = ?';
      params.push(sessionId);
    }

    if (timeRange) {
      const startTime = new Date(Date.now() - timeRange).toISOString();
      query += ' AND timestamp >= ?';
      params.push(startTime);
    }

    query += ' ORDER BY importance DESC, timestamp DESC LIMIT ?';
    params.push(limit);

    const memories = await this.all(query, params);
    
    // Update access count and last accessed
    for (const memory of memories) {
      await this.run(`
        UPDATE memories 
        SET access_count = access_count + 1, last_accessed = ? 
        WHERE id = ?
      `, [new Date().toISOString(), memory.id]);
    }

    return memories.map(m => ({
      ...m,
      content: JSON.parse(m.content),
      tags: JSON.parse(m.tags),
      relatedMemories: JSON.parse(m.related_memories)
    }));
  }

  async updateImportance(memoryId, newImportance, reason) {
    await this.run(`
      UPDATE memories 
      SET importance = ? 
      WHERE id = ?
    `, [newImportance, memoryId]);

    // Log importance change
    await this.storeMemory({
      id: `importance-update-${Date.now()}`,
      agentId: 'memory-orchestrator',
      timestamp: new Date().toISOString(),
      type: 'importance-update',
      content: {
        memoryId,
        oldImportance: null, // Would need to fetch this
        newImportance,
        reason
      },
      importance: 3
    });
  }

  async pruneMemories(retentionDays = 30, maxMemories = 10000) {
    const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000).toISOString();
    
    // Delete old, low-importance memories
    await this.run(`
      DELETE FROM memories 
      WHERE timestamp < ? 
      AND importance < 7 
      AND id NOT IN (
        SELECT id FROM memories 
        ORDER BY importance DESC, timestamp DESC 
        LIMIT ?
      )
    `, [cutoffDate, maxMemories]);
  }
}

module.exports = MemoryPersistence;
```

## Phase 5: Integration with Agents (Weeks 9-10)

### 5.1 Update Agent Template

Add memory integration to all agent files. Example for `agents/backend-expert.md`:

```markdown
## Memory Integration

Before starting any task, I will:
1. Query relevant memories from previous sessions
2. Check for similar problems and their solutions
3. Review collaboration patterns with other agents

After completing tasks, I will:
1. Store important decisions and rationales
2. Record successful patterns with high importance
3. Document errors and their resolutions
4. Update relationships with other agent memories

Memory queries I frequently use:
- `"backend architecture decisions for project:{projectName}"`
- `"API design patterns that worked well"`
- `"database optimization techniques"`
- `"collaboration outcomes with frontend-expert"`
```

### 5.2 Create Memory-Aware Orchestration

Update `agents/orchestration-agent.md`:

```markdown
## Memory-Enhanced Orchestration

### Pre-Task Memory Analysis
1. Query all relevant agent memories for similar tasks
2. Identify successful patterns and avoid past failures
3. Pre-load context for assigned agents
4. Create memory relationships for new task

### During Task Execution
1. Monitor agent memory creation
2. Identify cross-agent insights
3. Update importance scores based on impact
4. Create relationship links between related memories

### Post-Task Memory Synthesis
1. Aggregate all agent memories from task
2. Extract key learnings and patterns
3. Store orchestration-level insights
4. Update agent performance metrics in memory
```

## Implementation Timeline

| Week | Tasks |
|------|-------|
| 1-2  | Install and configure Memory Keeper |
| 3-4  | Set up Extended Memory Server |
| 5-6  | Build Unified Memory Layer |
| 7-8  | Implement Cross-Session Persistence |
| 9-10 | Integrate with all agents |
| 11-12| Testing, optimization, and documentation |

## Testing Strategy

### Unit Tests
- Memory storage and retrieval
- Importance scoring algorithms
- Session management
- Cross-agent memory sharing

### Integration Tests
- Multi-agent memory coordination
- Session continuity
- Memory pruning and optimization
- Performance under load

### Agent-Specific Tests
- Each agent's memory integration
- Cross-agent memory references
- Orchestration memory synthesis

## Monitoring and Metrics

Track these metrics to ensure memory system health:

1. **Storage Metrics**
   - Total memories stored
   - Storage growth rate
   - Average memory size

2. **Usage Metrics**
   - Memory retrieval frequency
   - Hit rate (useful memories / total retrieved)
   - Cross-agent reference rate

3. **Performance Metrics**
   - Query response time
   - Storage write time
   - Memory pruning efficiency

4. **Quality Metrics**
   - Importance score accuracy
   - Memory relevance scores
   - Agent performance improvement

## Security Considerations

1. **Data Privacy**
   - Encrypt sensitive memories
   - Implement access controls per agent
   - Audit memory access logs

2. **Data Integrity**
   - Backup memory databases regularly
   - Implement checksums for critical memories
   - Version control for memory schemas

3. **Resource Management**
   - Set memory quotas per agent
   - Implement automatic pruning
   - Monitor resource usage

## Next Steps

After implementing the memory system:

1. **Advanced Features**
   - Vector embeddings for semantic search
   - Memory clustering and categorization
   - Predictive memory pre-loading

2. **Integration Expansions**
   - Connect to external knowledge bases
   - Export memories for analysis
   - Memory visualization dashboard

3. **Performance Optimizations**
   - Implement memory caching
   - Optimize query performance
   - Compress historical memories