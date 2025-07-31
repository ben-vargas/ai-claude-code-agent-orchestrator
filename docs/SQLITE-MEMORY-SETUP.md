# SQLite Memory Setup Guide

This guide explains how to set up SQLite-based memory for the Claude Code Agent Orchestrator with automatic fallback to filesystem storage.

## Overview

The SQLite memory system provides:
- **High-performance memory storage** with rich querying
- **Automatic fallback** to filesystem when SQLite is unavailable
- **Cross-agent memory sharing** and relationships
- **Backwards compatibility** with existing Agent-*.md files
- **Migration tools** to move from filesystem to SQLite

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Agents                           │
├─────────────────────────────────────────────────────┤
│              SQLite Memory Adapter                  │
├─────────────────────────────────────────────────────┤
│   SQLite MCP     │        Filesystem               │
│   (Primary)      │        (Fallback)               │
│   ├─ Fast queries│        ├─ Agent-*.md files      │
│   ├─ Relations   │        ├─ Basic storage         │
│   └─ Analytics   │        └─ Compatible format     │
└─────────────────────────────────────────────────────┘
```

## Installation

### Step 1: Install SQLite Memory MCP Server

```bash
cd mcp-servers/sqlite-memory
npm install
```

### Step 2: Configure Claude MCP

Add to your Claude configuration file (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "sqlite-memory": {
      "command": "node",
      "args": ["/path/to/project/mcp-servers/sqlite-memory/index.js"],
      "env": {
        "MEMORY_DB_DIR": "~/.claude/agent-memory"
      }
    }
  }
}
```

### Step 3: Update Agent Configuration

The SQLite Memory Adapter (`agents/sqlite-memory-adapter.md`) is already configured to:
1. Check if SQLite MCP is available
2. Use SQLite for storage if available
3. Fall back to filesystem if not

### Step 4: Restart Claude Code

Restart Claude Code to load the new MCP server.

## Usage

### Checking Storage Status

Agents can check which storage backend is active:

```javascript
// In any agent
const storageStatus = await getStorageStatus();
console.log(storageStatus);
// Output:
// {
//   type: 'sqlite',  // or 'filesystem'
//   status: 'optimal',  // or 'degraded'
//   capabilities: ['fast-search', 'cross-agent', ...],
//   stats: { ... }
// }
```

### Storing Memories

The storage API is the same regardless of backend:

```javascript
// Store a memory (works with both SQLite and filesystem)
await storeMemory('backend-expert', {
  type: 'pattern',
  content: {
    pattern: 'Repository Pattern',
    implementation: 'Interface + Concrete class',
    benefits: 'Testability and flexibility'
  },
  importance: 8,
  tags: ['architecture', 'pattern'],
  relatedMemories: ['previous-pattern-id']  // Only works with SQLite
});
```

### Retrieving Memories

```javascript
// Basic retrieval
const memories = await retrieveMemory('backend-expert', {
  limit: 10,
  minImportance: 6
});

// Advanced search (SQLite only, limited functionality in filesystem)
const searchResults = await retrieveMemory('backend-expert', {
  searchQuery: 'authentication',
  tags: ['security', 'api'],
  timeRange: '7 days',
  includeRelated: true  // SQLite only
});
```

### Cross-Agent Search

```javascript
// Search across all agents (SQLite provides full functionality)
const allMemories = await crossAgentQuery({
  minImportance: 8,
  tags: ['successful-pattern'],
  searchQuery: 'optimization'
});
```

## Migration from Filesystem

### Automatic Migration

When SQLite becomes available, migrate existing memories:

```javascript
// Migrate a specific agent
await migrateToSQLite('backend-expert');

// Migrate all agents
const agents = ['backend-expert', 'frontend-expert', 'orchestration-agent'];
for (const agent of agents) {
  await migrateToSQLite(agent);
}
```

### Manual Migration via MCP

Use the `migrate_from_filesystem` tool:

```bash
# In Claude Code
"Migrate backend-expert memories from filesystem to SQLite"
```

## Fallback Behavior

When SQLite is unavailable, the system automatically:

1. **Stores memories** in `~/.claude/agent-workspaces/Agent-{name}.md`
2. **Maintains compatibility** with existing format
3. **Provides basic search** functionality
4. **Preserves all memories** for future migration

### Filesystem Format

```markdown
## Memory: 2024-01-15T10:30:00Z
- Type: pattern
- Importance: 8
- Tags: architecture, api
- Content: Repository pattern implementation
- Details: Used interface + concrete implementation for flexibility
```

## Advanced Features (SQLite Only)

### Memory Relations

```javascript
// Create relationships between memories
await addMemoryRelation({
  memory_id: 'backend-expert-123',
  related_memory_id: 'frontend-expert-456',
  relation_type: 'implements',
  strength: 0.9
});
```

### Memory Sharing

```javascript
// Share memory with another agent
await shareMemory({
  memory_id: 'backend-expert-123',
  share_with_agent: 'frontend-expert',
  access_level: 'read'
});
```

### Analytics

```javascript
// Get memory statistics
const stats = await getMemoryStats('backend-expert');
// Returns: total memories, average importance, top tags, etc.
```

## Performance Considerations

### SQLite Mode
- **Fast queries**: Indexed searches < 10ms
- **Rich filtering**: Complex queries supported
- **Scalable**: Handles 100k+ memories per agent

### Filesystem Mode
- **Slower searches**: Linear scan of files
- **Basic filtering**: Limited to simple matches
- **Memory limit**: Best under 1k memories per agent

## Troubleshooting

### SQLite Not Available

1. Check MCP configuration:
```bash
cat ~/.claude/claude_desktop_config.json | grep sqlite-memory
```

2. Verify MCP server is running:
```bash
# Check Claude logs for MCP server errors
```

3. Test connection manually:
```javascript
// In Claude Code
"Check SQLite memory connection status"
```

### Migration Issues

1. **Backup first**: Original files are renamed with `.backup` extension
2. **Verify migration**: Check memory count before/after
3. **Rollback**: Restore from backup files if needed

### Performance Issues

1. **Vacuum database**: Run periodically to optimize
```sql
VACUUM;
```

2. **Check indexes**: Ensure indexes are created
```sql
.indexes agent_memories
```

3. **Monitor size**: Database location: `~/.claude/agent-memory/agent-memories.db`

## Best Practices

1. **Regular backups**: SQLite database should be backed up
2. **Monitor storage type**: Agents should check and report degraded mode
3. **Consistent tagging**: Use same tags across storage types
4. **Importance scoring**: Be consistent regardless of backend
5. **Test fallback**: Periodically test filesystem fallback

## Future Enhancements

- Vector embeddings for semantic search (SQLite only)
- Automatic synchronization between storage types
- Cloud backup integration
- Memory visualization dashboard
- Performance metrics tracking