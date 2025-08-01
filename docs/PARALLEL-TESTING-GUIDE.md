# Parallel Orchestration Testing Guide

This guide provides step-by-step instructions for testing the parallel orchestration capabilities of the Claude Code Agent Orchestrator using multiple terminals.

## Prerequisites

Before testing parallel orchestration:

1. **Install the Orchestrator**:
   ```bash
   cd Claude-Code-Agent-Orchestrator
   ./install.sh
   ```

2. **Verify MCP Servers**:
   ```bash
   ./scripts/mcp-server-manager.sh --auto
   ```

3. **Install Hooks (Optional but Recommended)**:
   ```bash
   cd hooks && ./setup-hooks.sh
   ```

## Testing Scenarios

### 1. Basic Multi-Instance Test

This test verifies that multiple Claude Code instances can run simultaneously.

**Terminal 1 - Run the Test Script**:
```bash
cd Claude-Code-Agent-Orchestrator
./test-multi-instance.sh
```

This script will:
- Create 3 test workspaces
- Generate task files for each instance
- Display instructions for opening multiple Claude Code instances

**Terminal 2-4 - Monitor Progress**:
```bash
# Terminal 2
tail -f ~/.claude/agent-workspaces/instance-1/*

# Terminal 3
tail -f ~/.claude/agent-workspaces/instance-2/*

# Terminal 4
tail -f ~/.claude/agent-workspaces/instance-3/*
```

### 2. Advanced Parallel Orchestration Test

This simulates a real-world e-commerce project with 4 specialized agents working in parallel.

**Terminal 1 - Launch the Test**:
```bash
./test-parallel-orchestration.sh
```

This creates:
- Backend API development task
- Frontend dashboard task
- Database design task
- DevOps infrastructure task

**Terminal 2 - Monitor SQLite Coordination**:
```bash
# Watch agent coordination in real-time
watch -n 1 'sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
SELECT agent_id, task_id, status, title 
FROM agent_tasks 
WHERE datetime(created_at) > datetime(\"now\", \"-1 hour\")
ORDER BY created_at DESC LIMIT 10;"'
```

**Terminal 3 - Monitor Hook Activity** (if hooks installed):
```bash
~/.claude/hooks/monitor-agents.sh
```

**Terminal 4 - View Dashboard** (if hooks installed):
```bash
~/.claude/hooks/agent-dashboard.sh
```

### 3. Parallel Orchestrator Script

For production use with automatic terminal management:

**Terminal 1 - Run Parallel Orchestrator**:
```bash
./scripts/parallel-orchestrator.sh "Build Task Management SaaS" 3 4
```

Parameters:
- Project name: "Build Task Management SaaS"
- Project level: 3 (Professional)
- Max terminals: 4

This script will:
- Analyze the project and identify parallel workstreams
- Open new terminal windows/tabs for each agent
- Coordinate agents through SQLite
- Show real-time progress

### 4. Manual Parallel Testing

For complete control over parallel execution:

**Terminal 1 - Backend Agent**:
```bash
# In Claude Code
You are the backend-expert agent. Your task is to build the API for a task management system. 
Coordinate with other agents via SQLite at ~/.claude/agent-memory/agent-collaboration.db
Log your progress to ~/.claude/agent-workspaces/Agent-backend-expert.md
```

**Terminal 2 - Frontend Agent**:
```bash
# In Claude Code
You are the frontend-expert agent. Your task is to build the React dashboard.
Check ~/.claude/agent-memory/agent-collaboration.db for API specifications from backend-expert.
Log your progress to ~/.claude/agent-workspaces/Agent-frontend-expert.md
```

**Terminal 3 - Database Agent**:
```bash
# In Claude Code
You are the database-architect agent. Design the schema for the task management system.
Share your schema via SQLite for other agents to use.
Log your progress to ~/.claude/agent-workspaces/Agent-database-architect.md
```

**Terminal 4 - Orchestration Monitor**:
```bash
# Monitor all agents
while true; do
    clear
    echo "=== Active Agents ==="
    sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
    SELECT agent_id, status, title, 
           ROUND((julianday('now') - julianday(started_at)) * 1440) as minutes
    FROM agent_tasks 
    WHERE status IN ('in_progress', 'blocked')
    ORDER BY started_at;"
    
    echo -e "\n=== Recent Completions ==="
    sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
    SELECT agent_id, title, completed_at
    FROM agent_tasks 
    WHERE status = 'completed'
    AND datetime(completed_at) > datetime('now', '-1 hour')
    ORDER BY completed_at DESC LIMIT 5;"
    
    echo -e "\n=== Coordination Queue ==="
    sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
    SELECT from_agent, to_agent, task_type, priority
    FROM agent_coordination_queue
    WHERE status = 'pending'
    ORDER BY priority DESC, created_at;"
    
    sleep 5
done
```

## Monitoring Tools

### 1. Real-time Activity Monitor
```bash
# Simple tabular view
~/.claude/hooks/monitor-agents.sh
```

### 2. Advanced Dashboard
```bash
# Rich dashboard with graphs
~/.claude/hooks/agent-dashboard.sh
```

### 3. Slack Notifications
```bash
# Configure Slack
~/.claude/hooks/slack-notifier.sh configure

# Start monitoring daemon
~/.claude/hooks/slack-notifier.sh monitor
```

### 4. SQLite Queries

**Check Active Tasks**:
```sql
sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
SELECT * FROM agent_tasks WHERE status = 'in_progress';"
```

**View Coordination Queue**:
```sql
sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
SELECT * FROM agent_coordination_queue WHERE status = 'pending';"
```

**Missing Capabilities**:
```sql
sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
SELECT * FROM missing_capabilities ORDER BY frequency DESC;"
```

## Performance Testing

### Measure Parallel vs Sequential Performance

**Sequential Test**:
```bash
time ./scripts/orchestrator.sh "Build Todo App" 2 false 5
```

**Parallel Test**:
```bash
time ./scripts/parallel-orchestrator.sh "Build Todo App" 2 4
```

Compare execution times to see performance improvement.

## Tips for Effective Parallel Testing

1. **Start Small**: Begin with 2-3 agents before scaling up
2. **Monitor Resources**: Watch CPU and memory usage
3. **Use Project Levels**: Higher levels (4-5) benefit more from parallelization
4. **Check Dependencies**: Ensure dependent tasks are properly sequenced
5. **Review Coordination**: Check SQLite for proper task handoffs

## Troubleshooting

### Agents Not Coordinating
- Check SQLite database exists: `ls ~/.claude/agent-memory/`
- Verify tables: `sqlite3 ~/.claude/agent-memory/agent-collaboration.db ".tables"`
- Check permissions: `ls -la ~/.claude/agent-memory/`

### Terminal Windows Not Opening
- macOS: Grant Terminal full disk access in System Preferences
- Use iTerm2 or other terminal that supports AppleScript
- Run manually if automated opening fails

### Performance Issues
- Limit parallel agents based on system resources
- Use lower project levels for testing
- Monitor with `top` or Activity Monitor

## Example Test Results

### Parallel Execution Metrics
- **Sequential**: 45 minutes for full stack app
- **Parallel (4 agents)**: 12 minutes (3.75x speedup)
- **Resource Usage**: ~25% CPU per agent

### Coordination Efficiency
- **Task Handoffs**: <2 seconds via SQLite
- **Dependency Resolution**: Automatic with queue
- **Error Recovery**: 70% automatic recovery rate

## Next Steps

1. Run the basic multi-instance test first
2. Try the advanced parallel orchestration example
3. Monitor with hooks and dashboard
4. Experiment with your own projects
5. Share results and feedback!

Remember: Parallel orchestration shines with complex projects that have independent workstreams. Start with projects that naturally divide into parallel tasks for best results!