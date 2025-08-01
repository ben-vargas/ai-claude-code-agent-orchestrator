# Multi-Instance Claude Code Testing Guide

## Overview

This guide explains how to test multiple Claude Code instances working in parallel with MCP servers loaded and completing orchestrator-assigned tasks.

## Test Scripts

### 1. Basic Multi-Instance Test (`test-multi-instance.sh`)

Tests that multiple Claude instances can:
- Start independently
- Load MCP servers
- Complete simple assigned tasks
- Work with different workspaces

**Usage:**
```bash
# Run the test setup
./test-multi-instance.sh

# After completing manual steps, verify results
./test-multi-instance.sh --verify
```

### 2. Parallel Orchestration Test (`test-parallel-orchestration.sh`)

Simulates real parallel orchestration with:
- 4 specialized agents working simultaneously
- Complex project tasks (e-commerce MVP)
- MCP server integration
- SQLite memory sharing

**Usage:**
```bash
# Set up the test project
./test-parallel-orchestration.sh

# Navigate to workspace and launch all instances
cd ~/parallel-orchestration-test
./launch-all.sh

# Verify completion
./verify-completion.sh
```

## MCP Server Requirements

For full functionality, ensure these MCP servers are configured:

1. **filesystem** (Critical) - File operations
2. **memory** (Critical) - Cross-agent memory sharing
3. **git** (Recommended) - Version control
4. **web** (Optional) - Web search capabilities

Check MCP status:
```bash
./scripts/mcp-server-manager.sh --auto
```

## Test Scenarios

### Scenario 1: Simple Parallel Tasks
Each instance creates a simple greeting function independently.

**Expected Result:**
- 3 instances create 3 separate files
- Each file contains correct function
- All instances complete successfully

### Scenario 2: Complex Project Collaboration
4 specialized agents build an e-commerce MVP:
- Backend Expert: API development
- Frontend Expert: React components  
- Database Architect: Schema design
- DevOps Expert: Docker setup

**Expected Result:**
- All agents work simultaneously
- Each creates their deliverables
- SQLite memory captures decisions
- 3-4x faster than sequential

## Manual Testing Steps

### For macOS:

1. **Open Multiple Terminals**
   ```bash
   # Terminal 1
   cd ~/test-workspace/instance-1
   claude
   
   # Terminal 2
   cd ~/test-workspace/instance-2
   claude
   
   # Terminal 3
   cd ~/test-workspace/instance-3
   claude
   ```

2. **In Each Claude Instance**
   ```
   Please read TASK.md and complete the assigned task
   ```

3. **Monitor Progress**
   - Watch for file creation
   - Check SQLite memory updates
   - Observe MCP server usage

4. **Verify Results**
   ```bash
   ./verify-completion.sh
   ```

## Verification Checklist

✅ **Instance Start**
- [ ] Each instance starts without errors
- [ ] MCP servers load (check logs)
- [ ] No conflicts between instances

✅ **Task Execution**
- [ ] Each agent reads their task file
- [ ] Files are created in correct locations
- [ ] No permission errors

✅ **MCP Integration**
- [ ] Filesystem operations work
- [ ] Memory sharing occurs (if SQLite configured)
- [ ] No MCP server crashes

✅ **Parallel Performance**
- [ ] All instances work simultaneously
- [ ] No blocking between instances
- [ ] Faster than sequential execution

## Troubleshooting

### Issue: Claude command not found
```bash
# Check installation
which claude

# Add to PATH if needed
export PATH="$PATH:/Applications/Claude.app/Contents/MacOS"
```

### Issue: MCP servers not loading
```bash
# Check config
cat ~/.claude/claude_desktop_config.json

# Validate servers
./scripts/mcp-server-manager.sh
```

### Issue: Permission denied
```bash
# Fix permissions
chmod -R 755 ~/.claude/agents
chmod -R 755 ~/test-workspace
```

### Issue: SQLite memory not working
```bash
# Check if SQLite MCP is configured
grep -A5 "sqlite-memory" ~/.claude/claude_desktop_config.json

# Test SQLite directly
sqlite3 ~/.claude/agent-memory/test.db "SELECT 1;"
```

## Performance Metrics

### Sequential Execution (Traditional)
- Task 1: 15 minutes
- Task 2: 15 minutes  
- Task 3: 15 minutes
- Task 4: 15 minutes
- **Total: 60 minutes**

### Parallel Execution (Multi-Instance)
- All tasks: 15-20 minutes simultaneously
- Integration: 10 minutes
- **Total: 25-30 minutes** (2-3x faster)

## Advanced Testing

### Load Testing
Test with more instances:
```bash
INSTANCE_COUNT=10 ./test-multi-instance.sh
```

### Memory Sharing Test
Monitor SQLite during execution:
```bash
watch -n 1 'sqlite3 ~/.claude/agent-memory/agent-collaboration.db "SELECT agent_id, COUNT(*) FROM memories GROUP BY agent_id;"'
```

### Resource Monitoring
Track system resources:
```bash
# CPU and Memory
top -pid $(pgrep -f claude)

# Disk I/O
iotop
```

## Future Enhancements

1. **Automated Orchestration**
   - Spawn instances programmatically
   - Direct API control (when available)

2. **Inter-Instance Communication**
   - Real-time message passing
   - Shared task queues

3. **Dynamic Scaling**
   - Add/remove instances based on load
   - Automatic task redistribution

4. **Performance Analytics**
   - Track completion times
   - Identify bottlenecks
   - Optimize task distribution

## Conclusion

Multi-instance Claude Code enables true parallel execution for complex projects. With proper MCP server configuration and orchestration, you can achieve 2-4x performance improvements over sequential execution.

The key is ensuring:
1. Each instance has MCP servers loaded
2. Tasks are properly isolated
3. Memory sharing works (when needed)
4. No resource conflicts occur

Happy parallel orchestrating! 🚀