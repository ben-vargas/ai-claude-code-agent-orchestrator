# 🚀 Parallel Testing Quick Start

## Option 1: Automated Test (Easiest)

```bash
# Run this in Terminal 1
./test-parallel-orchestration.sh

# This creates an e-commerce project with 4 agents:
# - Backend API (Node.js/Express)
# - Frontend Dashboard (React)
# - Database Design (PostgreSQL)
# - DevOps Setup (Docker/K8s)
```

## Option 2: Monitor Everything

Open 4 terminals side-by-side:

**Terminal 1 - Run Test**:
```bash
./test-parallel-orchestration.sh
```

**Terminal 2 - Watch Agents**:
```bash
~/.claude/hooks/monitor-agents.sh
```

**Terminal 3 - View Dashboard**:
```bash
~/.claude/hooks/agent-dashboard.sh
```

**Terminal 4 - Check Coordination**:
```bash
watch -n 2 'sqlite3 ~/.claude/agent-memory/agent-collaboration.db "
SELECT agent_id, status, title FROM agent_tasks 
WHERE status = \"in_progress\" ORDER BY started_at;"'
```

## Option 3: Production Parallel Run

```bash
# Automatically opens multiple terminals
./scripts/parallel-orchestrator.sh "Your Project Name" 3 4

# Parameters:
# - "Your Project Name": What to build
# - 3: Quality level (1-5)
# - 4: Max parallel agents
```

## What You'll See

1. **Multiple Progress Bars**: Each agent shows its progress
2. **Real-time Coordination**: Agents share data via SQLite
3. **Automatic Handoffs**: Tasks flow between specialists
4. **Live Monitoring**: See everything happening in real-time

## Quick Commands

```bash
# Check active agents
sqlite3 ~/.claude/agent-memory/agent-collaboration.db \
  "SELECT * FROM agent_tasks WHERE status='in_progress';"

# View coordination queue  
sqlite3 ~/.claude/agent-memory/agent-collaboration.db \
  "SELECT * FROM agent_coordination_queue;"

# See missing tools/capabilities
sqlite3 ~/.claude/agent-memory/agent-collaboration.db \
  "SELECT * FROM missing_capabilities;"
```

## Tips

- Start with 2-3 agents for first test
- Use hooks for best visibility
- Higher project levels (4-5) benefit most from parallel execution
- Watch for "COORDINATION" messages in agent outputs

## Expected Results

- **Sequential**: ~45 min for full app
- **Parallel (4 agents)**: ~12 min (3.75x faster!)
- **CPU Usage**: ~25% per agent
- **Coordination Overhead**: <2 seconds

Ready to see the magic? Run the test! 🎭✨