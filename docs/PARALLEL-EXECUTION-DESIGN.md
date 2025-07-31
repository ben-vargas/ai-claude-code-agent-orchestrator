# Parallel Execution Design for Claude Code Agent Orchestrator

## Overview

This design document outlines how to implement true parallel execution of agents using multiple terminal instances, enabling significant speed improvements for complex projects.

## Current Limitations

- Single Claude Code instance = sequential execution
- "Parallel" execution is simulated through task ordering
- No true concurrency, leading to longer project completion times

## Proposed Solution: Multi-Terminal Orchestration

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Orchestration Controller                 │
│                    (Main Terminal)                       │
├─────────────────────────────────────────────────────────┤
│                  Terminal Manager                        │
│        ┌──────────┬──────────┬──────────┐              │
│        │ Term 1   │ Term 2   │ Term 3   │              │
│        │ Agent A  │ Agent B  │ Agent C  │              │
│        └──────────┴──────────┴──────────┘              │
├─────────────────────────────────────────────────────────┤
│                  Coordination Layer                      │
│    ├─ Task Queue                                        │
│    ├─ Progress Tracker                                  │
│    ├─ Result Aggregator                                 │
│    └─ Dependency Manager                                │
├─────────────────────────────────────────────────────────┤
│                   Shared Resources                       │
│    ├─ SQLite Memory                                     │
│    ├─ File System                                       │
│    └─ Progress Files                                    │
└─────────────────────────────────────────────────────────┘
```

## Implementation Approach

### 1. Terminal Spawning System

```javascript
// Terminal spawn configuration
const terminalConfig = {
  maxConcurrentTerminals: 3,  // Configurable based on system
  terminalCommand: 'claude',   // Or 'claude-code'
  workingDirectory: process.cwd(),
  environment: {
    CLAUDE_AGENT_MODE: 'worker',
    ORCHESTRATION_ID: generateId(),
    SHARED_MEMORY_PATH: '~/.claude/agent-memory/shared'
  }
};

// Spawn terminals for parallel agents
async function spawnAgentTerminal(agentName, taskId) {
  const terminal = await spawn(terminalConfig.terminalCommand, {
    cwd: terminalConfig.workingDirectory,
    env: {
      ...process.env,
      ...terminalConfig.environment,
      AGENT_NAME: agentName,
      TASK_ID: taskId
    }
  });
  
  return {
    terminal,
    agentName,
    taskId,
    startTime: Date.now(),
    status: 'running'
  };
}
```

### 2. Task Distribution Algorithm

```javascript
// Intelligent task distribution
class TaskDistributor {
  constructor(maxTerminals = 3) {
    this.maxTerminals = maxTerminals;
    this.activeTerminals = new Map();
    this.taskQueue = [];
    this.completedTasks = new Set();
  }
  
  async distributeTasks(phase) {
    const parallelizableTasks = this.identifyParallelTasks(phase);
    
    for (const taskGroup of parallelizableTasks) {
      // Assign tasks to available terminals
      await this.assignToTerminals(taskGroup);
    }
  }
  
  identifyParallelTasks(phase) {
    // Group tasks with no interdependencies
    const groups = [];
    const visited = new Set();
    
    for (const agent of phase.agents) {
      if (!visited.has(agent) && !this.hasDependencies(agent, phase)) {
        const group = this.findIndependentGroup(agent, phase, visited);
        groups.push(group);
      }
    }
    
    return groups;
  }
}
```

### 3. Communication Protocol

#### Inter-Terminal Communication via Files

```yaml
# ~/.claude/orchestration/session-{id}/status.yaml
session_id: "orch-2024-01-30-001"
phase: 2
active_agents:
  - agent: backend-expert
    terminal: 1
    status: running
    started: "2024-01-30T10:00:00Z"
    progress: 45
  - agent: frontend-expert
    terminal: 2
    status: running
    started: "2024-01-30T10:00:05Z"
    progress: 30
  - agent: database-architect
    terminal: 3
    status: completed
    started: "2024-01-30T10:00:00Z"
    completed: "2024-01-30T10:15:00Z"
    
completed_count: 1
total_count: 8
estimated_completion: "2024-01-30T10:45:00Z"
```

#### Agent Result Files

```json
// ~/.claude/orchestration/session-{id}/results/backend-expert.json
{
  "agent": "backend-expert",
  "taskId": "task-001",
  "status": "completed",
  "startTime": "2024-01-30T10:00:00Z",
  "endTime": "2024-01-30T10:20:00Z",
  "outputs": {
    "api_design": "path/to/api-spec.yaml",
    "implementation": "path/to/src/api/",
    "tests": "path/to/tests/api/"
  },
  "insights": [
    "Recommended GraphQL over REST for complex queries",
    "Implemented rate limiting at 1000 req/min",
    "Added webhook support for real-time updates"
  ],
  "decisions": {
    "database": "PostgreSQL with Redis cache",
    "authentication": "JWT with refresh tokens"
  },
  "nextAgents": ["frontend-expert", "qa-test-engineer"]
}
```

### 4. Orchestration Controller

```markdown
---
name: parallel-orchestration-controller
description: Manages parallel execution of agents across multiple terminals
---

## Parallel Execution Controller

### Initialization Phase
1. Analyze project requirements
2. Create execution plan with dependency graph
3. Identify parallelizable task groups
4. Estimate resource requirements

### Execution Management

#### Start Parallel Phase
```bash
# Create session directory
mkdir -p ~/.claude/orchestration/session-${SESSION_ID}/{status,results,logs}

# Initialize status file
echo "session_id: ${SESSION_ID}" > ~/.claude/orchestration/session-${SESSION_ID}/status.yaml

# Spawn terminals for parallel agents
for agent in ${PARALLEL_AGENTS}; do
  osascript -e "tell app \"Terminal\" to do script \"claude --agent ${agent} --session ${SESSION_ID}\""
done
```

#### Monitor Progress
- Check status file every 30 seconds
- Update orchestration-plan.md with aggregated progress
- Watch for completion signals
- Handle failures and reassignments

#### Aggregate Results
- Collect outputs from all completed agents
- Merge insights and decisions
- Identify conflicts or contradictions
- Prepare for next phase

### Coordination Patterns

1. **Fire-and-Forget**: Independent agents with no coordination
2. **Checkpoint Sync**: Agents sync at predefined checkpoints  
3. **Producer-Consumer**: One agent's output feeds another
4. **Race Condition**: First agent to complete wins
5. **Consensus**: Multiple agents validate same task
```

### 5. Terminal Management Scripts

Create `scripts/parallel-orchestrator.sh`:

```bash
#!/bin/bash
# Parallel Orchestration Launcher

SESSION_ID="orch-$(date +%Y%m%d-%H%M%S)"
ORCH_DIR="$HOME/.claude/orchestration/session-$SESSION_ID"
MAX_TERMINALS=3

# Create session structure
mkdir -p "$ORCH_DIR"/{status,results,logs,queue}

# Initialize session
cat > "$ORCH_DIR/config.json" << EOF
{
  "sessionId": "$SESSION_ID",
  "projectName": "$1",
  "projectLevel": ${2:-3},
  "maxTerminals": $MAX_TERMINALS,
  "startTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "initializing"
}
EOF

# Function to spawn agent terminal
spawn_agent() {
  local agent=$1
  local task_id=$2
  
  # macOS Terminal
  osascript <<EOF
    tell application "Terminal"
      set newWindow to do script "cd $PWD && claude-agent-worker --agent $agent --session $SESSION_ID --task $task_id"
      set custom title of newWindow to "Agent: $agent"
    end
EOF
  
  # Log spawn
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - Spawned $agent in new terminal" >> "$ORCH_DIR/logs/orchestration.log"
}

# Function to check terminal availability
get_active_terminals() {
  find "$ORCH_DIR/status" -name "*.active" -mmin -1 | wc -l
}

# Main orchestration loop
echo "🎭 Starting Parallel Orchestration"
echo "Session ID: $SESSION_ID"
echo "Max Terminals: $MAX_TERMINALS"

# Start orchestration controller in main terminal
claude --orchestrator parallel --session "$SESSION_ID" --project "$1" --level "${2:-3}"
```

### 6. Agent Worker Mode

Create `agents/agent-worker-mode.md`:

```markdown
---
name: agent-worker-mode
description: Configuration for agents running in worker terminals
---

## Worker Mode Behavior

When running in worker mode, I will:

1. **Check for assigned task**:
   - Read from `~/.claude/orchestration/session-{id}/queue/{agent-name}.task`
   - Validate task assignment

2. **Signal start**:
   - Create `~/.claude/orchestration/session-{id}/status/{agent-name}.active`
   - Update progress file regularly

3. **Execute independently**:
   - Focus solely on assigned task
   - Read shared memory for context
   - Write outputs to designated locations

4. **Report completion**:
   - Write results to `~/.claude/orchestration/session-{id}/results/{agent-name}.json`
   - Remove active status file
   - Signal next available

5. **Handle coordination**:
   - Check for coordination points
   - Wait at synchronization barriers
   - Share critical decisions via shared memory
```

### 7. Progress Visualization

Enhanced progress display for parallel execution:

```
🎭 PARALLEL ORCHESTRATION PROGRESS
==================================
Session: orch-2024-01-30-001
Project: AI Social Media Scheduler
Level: 3 (Alpha Production)

ACTIVE TERMINALS [3/3]
Terminal 1: 🔄 backend-expert      [████████░░░░░░] 55% API development
Terminal 2: 🔄 frontend-expert     [██████░░░░░░░░] 40% Dashboard UI
Terminal 3: ✅ database-architect  [██████████████] 100% Schema complete

PHASE PROGRESS
Phase 1: Research & Analysis    ✅ Complete (1h 23m)
Phase 2: Architecture & Design  ✅ Complete (2h 10m)
Phase 3: Implementation         🔄 In Progress (1h 45m elapsed)
  ├─ backend-expert            [████████░░░░░░] 55%
  ├─ frontend-expert           [██████░░░░░░░░] 40%
  ├─ ai-ml-expert              ⏳ Queued
  └─ data-analytics-expert     ⏳ Queued

RESOURCE UTILIZATION
CPU: ████████░░ 78%
Memory: ██████░░░░ 62%
Terminals: ███ 3/3

ESTIMATED COMPLETION
Current Phase: ~45 minutes remaining
Total Project: ~2 hours 30 minutes remaining

Recent Events:
[10:45:23] ✅ database-architect completed schema design
[10:44:15] 📝 backend-expert: Decision - Using GraphQL
[10:42:30] 🚀 frontend-expert started Dashboard implementation
[10:40:00] 🔄 Phase 3 started with 3 parallel agents
```

## Configuration Options

### Parallel Execution Settings

```json
{
  "parallelExecution": {
    "enabled": true,
    "maxConcurrentTerminals": 3,
    "terminalSpawnDelay": 2000,
    "coordinationCheckInterval": 30000,
    "resourceLimits": {
      "maxCpuPercent": 80,
      "maxMemoryMB": 4096
    },
    "strategies": {
      "level1": "aggressive",    // Max parallel, no coordination
      "level2": "balanced",      // Moderate parallel with checkpoints
      "level3": "balanced",      
      "level4": "conservative",  // Limited parallel, more coordination
      "level5": "conservative"
    },
    "failureHandling": {
      "maxRetries": 2,
      "reassignmentDelay": 60000,
      "fallbackToSequential": true
    }
  }
}
```

## Benefits

1. **Speed Improvement**: 3x faster for independent tasks
2. **Resource Utilization**: Better CPU/memory usage
3. **Real Parallelism**: True concurrent execution
4. **Failure Isolation**: One agent failure doesn't block others
5. **Scalability**: Add more terminals as needed

## Challenges & Solutions

### Challenge 1: Resource Contention
**Solution**: Implement resource locking for shared files

### Challenge 2: Coordination Overhead
**Solution**: Minimize sync points, use async communication

### Challenge 3: Terminal Management
**Solution**: Automatic cleanup and terminal recycling

### Challenge 4: Result Conflicts
**Solution**: Conflict resolution protocol with priorities

## Next Steps

1. Implement terminal spawning script
2. Create worker mode for agents
3. Build coordination protocol
4. Add progress aggregation
5. Test with real projects
6. Optimize resource usage
7. Add failure recovery