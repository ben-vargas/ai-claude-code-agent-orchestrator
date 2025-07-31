# MCP Memory Solutions for Agent Systems

## Overview

The Model Context Protocol (MCP) has spawned multiple memory persistence implementations specifically designed for Claude Code and agent systems. This document analyzes the available solutions and their applicability to multi-agent orchestration.

## Available MCP Memory Servers (2025)

### 1. Extended Memory Server

**Repository**: `mcp-extended-memory`  
**Status**: Production-ready (400+ tests)

**Features:**
- Multi-project support
- Automatic importance scoring
- Tag-based organization
- Cross-conversation persistence
- Advanced search capabilities

**Technical Implementation:**
```typescript
// Example usage pattern
const memory = new ExtendedMemoryServer({
  projectId: "claude-orchestrator",
  autoScore: true,
  tags: ["agent-decisions", "task-progress", "context"]
});

// Store agent decision
await memory.store({
  content: "Selected backend-expert for API design",
  importance: 0.8,
  tags: ["orchestration", "agent-selection"],
  metadata: {
    taskId: "task-123",
    timestamp: Date.now()
  }
});
```

**Pros:**
- Battle-tested in production
- Sophisticated importance algorithm
- Excellent for multi-agent coordination

**Cons:**
- Requires TypeScript/Node.js
- Complex configuration for simple use cases

### 2. MCP Memory Service

**Repository**: `doobidoo/mcp-memory-service`  
**Backend**: ChromaDB + Sentence Transformers

**Features:**
- Semantic memory storage
- Vector similarity search
- Zero configuration start
- Context-aware operations
- ChromaDB persistence

**Technical Implementation:**
```python
# Semantic storage example
{
  "command": "store",
  "memory": {
    "content": "User prefers microservices architecture",
    "embedding": "auto-generated",
    "metadata": {
      "agent": "cloud-architect",
      "confidence": 0.9
    }
  }
}

# Semantic retrieval
{
  "command": "recall",
  "query": "What architecture style should we use?",
  "limit": 5
}
```

**Pros:**
- Semantic search capabilities
- Great for finding related memories
- Automatic embeddings

**Cons:**
- Requires ChromaDB setup
- Higher resource usage
- Python dependency

### 3. Memory Keeper

**Repository**: `mkreyman/mcp-memory-keeper`  
**Backend**: SQLite

**Features:**
- Simple SQLite storage
- Project-specific contexts
- Auto-created databases
- Lightweight and fast
- Command-based interface

**Technical Implementation:**
```json
// Store memory
{
  "method": "memory/store",
  "params": {
    "key": "api_design_decisions",
    "value": {
      "pattern": "RESTful",
      "versioning": "URL-based",
      "authentication": "JWT"
    },
    "project": "saas-platform"
  }
}

// Retrieve memory
{
  "method": "memory/get",
  "params": {
    "key": "api_design_decisions",
    "project": "saas-platform"
  }
}
```

**Pros:**
- Zero dependencies (SQLite built-in)
- Fast and lightweight
- Easy to backup/migrate

**Cons:**
- No semantic search
- Basic key-value storage
- Limited query capabilities

### 4. Claude Thread Continuity

**Repository**: `claude-thread-continuity`  
**Focus**: Conversation persistence

**Features:**
- Full conversation history
- Project state tracking
- User preference storage
- Multi-session workflows
- Automatic context resumption

**Technical Implementation:**
```json
{
  "thread": {
    "id": "project-xyz-thread-1",
    "sessions": [
      {
        "timestamp": "2025-01-20T10:00:00Z",
        "messages": [...],
        "context": {
          "activeAgents": ["backend-expert", "database-architect"],
          "completedTasks": ["api-design", "schema-draft"],
          "decisions": [...]
        }
      }
    ]
  }
}
```

**Pros:**
- Preserves full conversation context
- Excellent for long-running projects
- Natural conversation flow

**Cons:**
- Large storage requirements
- Focused on conversation, not data

## Comparison Matrix

| Feature | Extended Memory | MCP Memory Service | Memory Keeper | Thread Continuity |
|---------|-----------------|-------------------|---------------|-------------------|
| Backend | Custom | ChromaDB | SQLite | Custom |
| Semantic Search | ❌ | ✅ | ❌ | ❌ |
| Multi-Project | ✅ | ✅ | ✅ | ✅ |
| Auto-Importance | ✅ | ❌ | ❌ | ❌ |
| Resource Usage | Medium | High | Low | Medium |
| Setup Complexity | Medium | High | Low | Low |
| Query Capabilities | Advanced | Semantic | Basic | Limited |
| Best For | Complex Systems | AI/ML Projects | Simple Storage | Conversations |

## Integration Strategy for Agent Orchestrator

### Recommended Architecture

```python
class UnifiedMemoryLayer:
    """Unified memory interface for all agents"""
    
    def __init__(self):
        # Use Memory Keeper for fast lookups
        self.quick_memory = MemoryKeeperClient()
        
        # Use MCP Memory Service for semantic search
        self.semantic_memory = MCPMemoryServiceClient()
        
        # Use Extended Memory for importance scoring
        self.priority_memory = ExtendedMemoryClient()
        
        # Use Thread Continuity for conversations
        self.conversation_memory = ThreadContinuityClient()
    
    async def store(self, content: dict, agent: str):
        """Store memory across all appropriate services"""
        
        # Quick access storage
        await self.quick_memory.store(
            key=f"{agent}:{content['task_id']}",
            value=content
        )
        
        # Semantic storage for searchability
        if content.get('insights'):
            await self.semantic_memory.store(
                content=content['insights'],
                metadata={'agent': agent}
            )
        
        # Important decisions go to priority memory
        if content.get('importance', 0) > 0.7:
            await self.priority_memory.store(
                content=content,
                importance=content['importance'],
                tags=[agent, 'decision']
            )
    
    async def recall(self, query: str, context: dict = None):
        """Intelligent recall from appropriate service"""
        
        # Try quick lookup first
        if context.get('task_id'):
            quick_result = await self.quick_memory.get(
                key=f"*:{context['task_id']}"
            )
            if quick_result:
                return quick_result
        
        # Semantic search for relevant memories
        semantic_results = await self.semantic_memory.search(
            query=query,
            filter={'agent': context.get('agent')}
        )
        
        # Get high-importance related memories
        important_results = await self.priority_memory.search(
            tags=[context.get('agent')],
            min_importance=0.7
        )
        
        return self.merge_results(
            quick_result,
            semantic_results,
            important_results
        )
```

### Memory Strategy by Agent Type

#### Engineering Agents
```yaml
backend-expert:
  primary: memory-keeper  # Fast technical decisions
  secondary: extended-memory  # Important architecture choices
  
frontend-expert:
  primary: memory-keeper  # Component decisions
  secondary: thread-continuity  # UI/UX discussions
```

#### Strategy Agents
```yaml
business-analyst:
  primary: mcp-memory-service  # Semantic search for insights
  secondary: extended-memory  # Important findings
  
product-strategy-expert:
  primary: extended-memory  # All decisions are important
  secondary: mcp-memory-service  # Related feature search
```

#### Orchestration Agent
```yaml
orchestration-agent:
  primary: extended-memory  # Task coordination
  secondary: memory-keeper  # Quick task lookups
  tertiary: thread-continuity  # Full execution history
```

## Implementation Recommendations

### 1. Start Simple
Begin with Memory Keeper for basic persistence:
- Lowest resource usage
- Easiest setup
- Sufficient for MVP

### 2. Add Semantic Search
Integrate MCP Memory Service for intelligent recall:
- When agents need to find related information
- For cross-agent knowledge sharing
- For user query understanding

### 3. Implement Importance Scoring
Add Extended Memory for critical decisions:
- Orchestration decisions
- Architectural choices
- Business strategies

### 4. Enable Conversation Persistence
Use Thread Continuity for long projects:
- Multi-session development
- Complex workflows
- Team collaboration

## Configuration Example

```json
{
  "memory": {
    "default": "memory-keeper",
    "services": {
      "memory-keeper": {
        "enabled": true,
        "db_path": "~/.claude/orchestrator/memory.db"
      },
      "mcp-memory-service": {
        "enabled": false,
        "chromadb_path": "~/.claude/orchestrator/chroma",
        "embedding_model": "all-MiniLM-L6-v2"
      },
      "extended-memory": {
        "enabled": false,
        "importance_threshold": 0.7,
        "max_memories": 10000
      },
      "thread-continuity": {
        "enabled": true,
        "max_sessions": 50,
        "compress_old": true
      }
    },
    "agent_overrides": {
      "orchestration-agent": {
        "services": ["extended-memory", "memory-keeper"]
      },
      "business-analyst": {
        "services": ["mcp-memory-service"]
      }
    }
  }
}
```

## Future Considerations

### Unified Memory Protocol
Develop a standard protocol that all memory services implement:
```typescript
interface UnifiedMemoryProtocol {
  store(key: string, value: any, metadata?: any): Promise<void>
  get(key: string): Promise<any>
  search(query: string, options?: SearchOptions): Promise<any[]>
  delete(key: string): Promise<void>
  export(): Promise<MemoryDump>
  import(dump: MemoryDump): Promise<void>
}
```

### Memory Migration Tools
Create tools for migrating between memory backends:
- Export from one format
- Transform to another
- Preserve metadata and relationships

### Performance Optimization
- Memory caching layer
- Lazy loading strategies
- Memory compression
- Automated cleanup

## Conclusion

MCP memory solutions in 2025 offer diverse approaches to persistence:
- **Memory Keeper** for simplicity
- **MCP Memory Service** for semantic search
- **Extended Memory** for importance-based recall
- **Thread Continuity** for conversation persistence

The Claude Code Agent Orchestrator should implement a unified memory layer that leverages the strengths of each solution, allowing agents to use the most appropriate memory service for their specific needs.