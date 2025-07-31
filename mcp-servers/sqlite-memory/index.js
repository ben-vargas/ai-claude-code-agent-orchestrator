#!/usr/bin/env node
/**
 * SQLite Memory MCP Server for Claude Code Agent Orchestrator
 * Provides SQLite-based memory storage with rich querying capabilities
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

class SQLiteMemoryServer {
  constructor() {
    // Initialize database path
    const dbDir = process.env.MEMORY_DB_DIR || path.join(process.env.HOME, '.claude', 'agent-memory');
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }
    
    this.dbPath = path.join(dbDir, 'agent-memories.db');
    this.db = new Database(this.dbPath);
    
    // Initialize database schema
    this.initializeDatabase();
    
    // Initialize MCP server
    this.server = new Server(
      {
        name: 'sqlite-memory',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );
    
    this.setupHandlers();
  }

  initializeDatabase() {
    // Enable foreign keys
    this.db.exec('PRAGMA foreign_keys = ON');
    
    // Main memories table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS agent_memories (
        id TEXT PRIMARY KEY,
        agent_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT DEFAULT 'general',
        content TEXT NOT NULL,
        importance INTEGER DEFAULT 5,
        tags TEXT DEFAULT '[]',
        session_id TEXT,
        access_count INTEGER DEFAULT 0,
        last_accessed TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Create indexes
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_agent_timestamp 
      ON agent_memories(agent_id, timestamp DESC);
      
      CREATE INDEX IF NOT EXISTS idx_importance 
      ON agent_memories(importance DESC);
      
      CREATE INDEX IF NOT EXISTS idx_session 
      ON agent_memories(session_id);
      
      CREATE INDEX IF NOT EXISTS idx_tags
      ON agent_memories(tags);
    `);
    
    // Memory relationships table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS memory_relations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id TEXT NOT NULL,
        related_memory_id TEXT NOT NULL,
        relation_type TEXT DEFAULT 'related',
        strength REAL DEFAULT 0.5,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memory_id) REFERENCES agent_memories(id) ON DELETE CASCADE,
        FOREIGN KEY (related_memory_id) REFERENCES agent_memories(id) ON DELETE CASCADE,
        UNIQUE(memory_id, related_memory_id)
      )
    `);
    
    // Shared memories table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS shared_memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id TEXT NOT NULL,
        shared_with_agent TEXT NOT NULL,
        shared_at TEXT DEFAULT CURRENT_TIMESTAMP,
        access_level TEXT DEFAULT 'read',
        FOREIGN KEY (memory_id) REFERENCES agent_memories(id) ON DELETE CASCADE,
        UNIQUE(memory_id, shared_with_agent)
      )
    `);
    
    // Memory statistics table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS memory_stats (
        agent_id TEXT PRIMARY KEY,
        total_memories INTEGER DEFAULT 0,
        avg_importance REAL DEFAULT 5.0,
        last_memory_at TEXT,
        most_used_tags TEXT DEFAULT '[]',
        storage_size_bytes INTEGER DEFAULT 0
      )
    `);
  }

  setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'store_memory',
          description: 'Store a memory for an agent',
          inputSchema: {
            type: 'object',
            properties: {
              agent_id: { type: 'string', description: 'The agent storing the memory' },
              content: { type: 'object', description: 'The memory content' },
              type: { type: 'string', description: 'Type of memory (general, pattern, error, insight)' },
              importance: { type: 'integer', minimum: 1, maximum: 10, description: 'Importance score' },
              tags: { type: 'array', items: { type: 'string' }, description: 'Tags for categorization' },
              session_id: { type: 'string', description: 'Session ID for continuity' },
              related_memories: { type: 'array', items: { type: 'string' }, description: 'Related memory IDs' }
            },
            required: ['agent_id', 'content']
          }
        },
        {
          name: 'retrieve_memories',
          description: 'Retrieve memories for an agent with filtering',
          inputSchema: {
            type: 'object',
            properties: {
              agent_id: { type: 'string', description: 'The agent ID to retrieve memories for' },
              limit: { type: 'integer', description: 'Maximum number of memories to return' },
              min_importance: { type: 'integer', description: 'Minimum importance score' },
              tags: { type: 'array', items: { type: 'string' }, description: 'Filter by tags' },
              search_query: { type: 'string', description: 'Search in memory content' },
              time_range_days: { type: 'integer', description: 'Limit to memories from last N days' },
              include_shared: { type: 'boolean', description: 'Include memories shared by other agents' }
            },
            required: ['agent_id']
          }
        },
        {
          name: 'search_all_memories',
          description: 'Search across all agent memories',
          inputSchema: {
            type: 'object',
            properties: {
              query: { type: 'string', description: 'Search query' },
              min_importance: { type: 'integer', description: 'Minimum importance score' },
              tags: { type: 'array', items: { type: 'string' }, description: 'Filter by tags' },
              limit: { type: 'integer', description: 'Maximum results' }
            },
            required: ['query']
          }
        },
        {
          name: 'update_importance',
          description: 'Update the importance score of a memory',
          inputSchema: {
            type: 'object',
            properties: {
              memory_id: { type: 'string', description: 'Memory ID to update' },
              new_importance: { type: 'integer', minimum: 1, maximum: 10, description: 'New importance score' },
              reason: { type: 'string', description: 'Reason for update' }
            },
            required: ['memory_id', 'new_importance']
          }
        },
        {
          name: 'share_memory',
          description: 'Share a memory with another agent',
          inputSchema: {
            type: 'object',
            properties: {
              memory_id: { type: 'string', description: 'Memory ID to share' },
              share_with_agent: { type: 'string', description: 'Agent to share with' },
              access_level: { type: 'string', enum: ['read', 'write'], description: 'Access level' }
            },
            required: ['memory_id', 'share_with_agent']
          }
        },
        {
          name: 'add_memory_relation',
          description: 'Create a relationship between memories',
          inputSchema: {
            type: 'object',
            properties: {
              memory_id: { type: 'string', description: 'Source memory ID' },
              related_memory_id: { type: 'string', description: 'Related memory ID' },
              relation_type: { type: 'string', description: 'Type of relation' },
              strength: { type: 'number', minimum: 0, maximum: 1, description: 'Relation strength' }
            },
            required: ['memory_id', 'related_memory_id']
          }
        },
        {
          name: 'get_memory_stats',
          description: 'Get memory statistics for an agent or all agents',
          inputSchema: {
            type: 'object',
            properties: {
              agent_id: { type: 'string', description: 'Agent ID (optional, omit for all agents)' }
            }
          }
        },
        {
          name: 'migrate_from_filesystem',
          description: 'Migrate memories from filesystem to SQLite',
          inputSchema: {
            type: 'object',
            properties: {
              workspace_path: { type: 'string', description: 'Path to agent workspace directory' },
              agent_id: { type: 'string', description: 'Agent ID to migrate' }
            },
            required: ['workspace_path', 'agent_id']
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'store_memory':
          return this.storeMemory(request.params.arguments);
        case 'retrieve_memories':
          return this.retrieveMemories(request.params.arguments);
        case 'search_all_memories':
          return this.searchAllMemories(request.params.arguments);
        case 'update_importance':
          return this.updateImportance(request.params.arguments);
        case 'share_memory':
          return this.shareMemory(request.params.arguments);
        case 'add_memory_relation':
          return this.addMemoryRelation(request.params.arguments);
        case 'get_memory_stats':
          return this.getMemoryStats(request.params.arguments);
        case 'migrate_from_filesystem':
          return this.migrateFromFilesystem(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  async storeMemory(args) {
    const {
      agent_id,
      content,
      type = 'general',
      importance = 5,
      tags = [],
      session_id = null,
      related_memories = []
    } = args;

    const memoryId = `${agent_id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    try {
      // Store the memory
      const stmt = this.db.prepare(`
        INSERT INTO agent_memories 
        (id, agent_id, timestamp, type, content, importance, tags, session_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `);
      
      stmt.run(
        memoryId,
        agent_id,
        new Date().toISOString(),
        type,
        JSON.stringify(content),
        importance,
        JSON.stringify(tags),
        session_id
      );

      // Add relations if provided
      if (related_memories.length > 0) {
        const relationStmt = this.db.prepare(`
          INSERT OR IGNORE INTO memory_relations 
          (memory_id, related_memory_id, relation_type, strength)
          VALUES (?, ?, ?, ?)
        `);
        
        for (const relatedId of related_memories) {
          relationStmt.run(memoryId, relatedId, 'related', 0.7);
        }
      }

      // Update statistics
      this.updateAgentStats(agent_id);

      return {
        content: [{
          type: 'text',
          text: `Memory stored successfully with ID: ${memoryId}`
        }],
        memoryId
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error storing memory: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async retrieveMemories(args) {
    const {
      agent_id,
      limit = 100,
      min_importance = 0,
      tags = [],
      search_query = null,
      time_range_days = null,
      include_shared = false
    } = args;

    try {
      let query = `
        SELECT DISTINCT m.* FROM agent_memories m
        WHERE (m.agent_id = ? OR (? AND m.id IN (
          SELECT memory_id FROM shared_memories WHERE shared_with_agent = ?
        )))
        AND m.importance >= ?
      `;
      
      const params = [agent_id, include_shared, agent_id, min_importance];

      // Add tag filter
      if (tags.length > 0) {
        const tagConditions = tags.map(() => 'tags LIKE ?').join(' OR ');
        query += ` AND (${tagConditions})`;
        tags.forEach(tag => params.push(`%"${tag}"%`));
      }

      // Add search filter
      if (search_query) {
        query += ` AND content LIKE ?`;
        params.push(`%${search_query}%`);
      }

      // Add time range filter
      if (time_range_days) {
        query += ` AND datetime(timestamp) > datetime('now', '-${time_range_days} days')`;
      }

      query += ` ORDER BY importance DESC, timestamp DESC LIMIT ?`;
      params.push(limit);

      const memories = this.db.prepare(query).all(...params);
      
      // Update access count
      const updateStmt = this.db.prepare(`
        UPDATE agent_memories 
        SET access_count = access_count + 1, 
            last_accessed = ?
        WHERE id = ?
      `);
      
      const now = new Date().toISOString();
      memories.forEach(m => updateStmt.run(now, m.id));

      // Parse JSON fields
      const parsedMemories = memories.map(m => ({
        ...m,
        content: JSON.parse(m.content),
        tags: JSON.parse(m.tags)
      }));

      return {
        content: [{
          type: 'text',
          text: `Retrieved ${parsedMemories.length} memories for ${agent_id}`
        }],
        memories: parsedMemories
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error retrieving memories: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async searchAllMemories(args) {
    const {
      query,
      min_importance = 0,
      tags = [],
      limit = 50
    } = args;

    try {
      let sqlQuery = `
        SELECT * FROM agent_memories
        WHERE content LIKE ?
        AND importance >= ?
      `;
      
      const params = [`%${query}%`, min_importance];

      if (tags.length > 0) {
        const tagConditions = tags.map(() => 'tags LIKE ?').join(' OR ');
        sqlQuery += ` AND (${tagConditions})`;
        tags.forEach(tag => params.push(`%"${tag}"%`));
      }

      sqlQuery += ` ORDER BY importance DESC, timestamp DESC LIMIT ?`;
      params.push(limit);

      const memories = this.db.prepare(sqlQuery).all(...params);
      
      const parsedMemories = memories.map(m => ({
        ...m,
        content: JSON.parse(m.content),
        tags: JSON.parse(m.tags)
      }));

      // Group by agent
      const groupedMemories = parsedMemories.reduce((acc, memory) => {
        if (!acc[memory.agent_id]) {
          acc[memory.agent_id] = [];
        }
        acc[memory.agent_id].push(memory);
        return acc;
      }, {});

      return {
        content: [{
          type: 'text',
          text: `Found ${parsedMemories.length} memories across ${Object.keys(groupedMemories).length} agents`
        }],
        memories: parsedMemories,
        groupedByAgent: groupedMemories
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error searching memories: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async updateImportance(args) {
    const { memory_id, new_importance, reason = '' } = args;

    try {
      const stmt = this.db.prepare(`
        UPDATE agent_memories 
        SET importance = ?, 
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `);
      
      const result = stmt.run(new_importance, memory_id);
      
      if (result.changes === 0) {
        return {
          content: [{
            type: 'text',
            text: `Memory with ID ${memory_id} not found`
          }],
          isError: true
        };
      }

      // Log the update as a new memory
      if (reason) {
        await this.storeMemory({
          agent_id: 'sqlite-memory-adapter',
          content: {
            action: 'importance_update',
            memory_id,
            new_importance,
            reason
          },
          type: 'system',
          importance: 3,
          tags: ['importance-update', 'system']
        });
      }

      return {
        content: [{
          type: 'text',
          text: `Updated importance of memory ${memory_id} to ${new_importance}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error updating importance: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async shareMemory(args) {
    const { memory_id, share_with_agent, access_level = 'read' } = args;

    try {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO shared_memories 
        (memory_id, shared_with_agent, access_level)
        VALUES (?, ?, ?)
      `);
      
      stmt.run(memory_id, share_with_agent, access_level);

      return {
        content: [{
          type: 'text',
          text: `Memory ${memory_id} shared with ${share_with_agent} (${access_level} access)`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error sharing memory: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async addMemoryRelation(args) {
    const {
      memory_id,
      related_memory_id,
      relation_type = 'related',
      strength = 0.5
    } = args;

    try {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO memory_relations 
        (memory_id, related_memory_id, relation_type, strength)
        VALUES (?, ?, ?, ?)
      `);
      
      stmt.run(memory_id, related_memory_id, relation_type, strength);

      return {
        content: [{
          type: 'text',
          text: `Added ${relation_type} relation between ${memory_id} and ${related_memory_id}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error adding relation: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async getMemoryStats(args) {
    const { agent_id } = args;

    try {
      if (agent_id) {
        // Stats for specific agent
        const stats = this.db.prepare(`
          SELECT 
            COUNT(*) as total_memories,
            AVG(importance) as avg_importance,
            MAX(timestamp) as last_memory,
            SUM(LENGTH(content)) as total_size,
            MAX(access_count) as most_accessed_count
          FROM agent_memories
          WHERE agent_id = ?
        `).get(agent_id);

        // Get most used tags
        const memories = this.db.prepare(`
          SELECT tags FROM agent_memories WHERE agent_id = ?
        `).all(agent_id);
        
        const tagCounts = {};
        memories.forEach(m => {
          const tags = JSON.parse(m.tags);
          tags.forEach(tag => {
            tagCounts[tag] = (tagCounts[tag] || 0) + 1;
          });
        });
        
        const topTags = Object.entries(tagCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 5)
          .map(([tag]) => tag);

        return {
          content: [{
            type: 'text',
            text: `Memory statistics for ${agent_id}`
          }],
          stats: {
            ...stats,
            top_tags: topTags
          }
        };
      } else {
        // Global stats
        const globalStats = this.db.prepare(`
          SELECT 
            COUNT(*) as total_memories,
            COUNT(DISTINCT agent_id) as total_agents,
            AVG(importance) as avg_importance,
            SUM(LENGTH(content)) as total_size
          FROM agent_memories
        `).get();

        const agentStats = this.db.prepare(`
          SELECT 
            agent_id,
            COUNT(*) as memory_count,
            AVG(importance) as avg_importance
          FROM agent_memories
          GROUP BY agent_id
          ORDER BY memory_count DESC
        `).all();

        return {
          content: [{
            type: 'text',
            text: 'Global memory statistics'
          }],
          globalStats,
          agentStats
        };
      }
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error getting stats: ${error.message}`
        }],
        isError: true
      };
    }
  }

  async migrateFromFilesystem(args) {
    const { workspace_path, agent_id } = args;

    try {
      const filePath = path.join(workspace_path, `Agent-${agent_id}.md`);
      
      if (!fs.existsSync(filePath)) {
        return {
          content: [{
            type: 'text',
            text: `No workspace file found for ${agent_id}`
          }],
          isError: true
        };
      }

      const content = fs.readFileSync(filePath, 'utf8');
      const memories = this.parseMarkdownMemories(content);
      
      let migrated = 0;
      for (const memory of memories) {
        await this.storeMemory({
          agent_id,
          content: memory.content || memory,
          type: memory.type || 'migrated',
          importance: memory.importance || 5,
          tags: memory.tags || ['migrated-from-filesystem'],
          session_id: memory.sessionId || `migration-${Date.now()}`
        });
        migrated++;
      }

      // Backup original file
      const backupPath = `${filePath}.backup-${Date.now()}`;
      fs.renameSync(filePath, backupPath);

      return {
        content: [{
          type: 'text',
          text: `Migrated ${migrated} memories from filesystem for ${agent_id}. Original backed up to ${backupPath}`
        }],
        migrated,
        backupPath
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Error during migration: ${error.message}`
        }],
        isError: true
      };
    }
  }

  parseMarkdownMemories(content) {
    const memories = [];
    const lines = content.split('\n');
    let currentMemory = null;
    let inMemoryBlock = false;

    for (const line of lines) {
      if (line.startsWith('## Memory:') || line.startsWith('### Memory:')) {
        if (currentMemory) {
          memories.push(currentMemory);
        }
        currentMemory = {
          timestamp: new Date().toISOString(),
          content: {},
          tags: []
        };
        inMemoryBlock = true;
      } else if (inMemoryBlock && line.trim() === '') {
        if (currentMemory) {
          memories.push(currentMemory);
          currentMemory = null;
          inMemoryBlock = false;
        }
      } else if (inMemoryBlock && currentMemory) {
        // Parse memory attributes
        if (line.startsWith('- Importance:')) {
          currentMemory.importance = parseInt(line.split(':')[1].trim());
        } else if (line.startsWith('- Tags:')) {
          currentMemory.tags = line.split(':')[1].trim().split(',').map(t => t.trim());
        } else if (line.startsWith('- Type:')) {
          currentMemory.type = line.split(':')[1].trim();
        } else if (line.startsWith('- ')) {
          const [key, ...valueParts] = line.substring(2).split(':');
          if (key && valueParts.length > 0) {
            currentMemory.content[key.trim()] = valueParts.join(':').trim();
          }
        }
      }
    }

    if (currentMemory) {
      memories.push(currentMemory);
    }

    return memories;
  }

  updateAgentStats(agent_id) {
    try {
      const stats = this.db.prepare(`
        SELECT 
          COUNT(*) as total,
          AVG(importance) as avg_imp
        FROM agent_memories
        WHERE agent_id = ?
      `).get(agent_id);

      this.db.prepare(`
        INSERT OR REPLACE INTO memory_stats 
        (agent_id, total_memories, avg_importance, last_memory_at)
        VALUES (?, ?, ?, ?)
      `).run(
        agent_id,
        stats.total,
        stats.avg_imp,
        new Date().toISOString()
      );
    } catch (error) {
      console.error('Error updating stats:', error);
    }
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('SQLite Memory MCP Server started');
  }
}

// Start the server
const server = new SQLiteMemoryServer();
server.start().catch(console.error);