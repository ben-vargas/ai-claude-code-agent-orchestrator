# Claude Code Hooks for Agent Tracking

## Overview

Claude Code hooks provide comprehensive tracking of all agent activities, capturing progress, failures, successes, and tool usage. All data is stored in SQLite with automatic file backups for visibility and debugging.

## Architecture

```
Claude Code
    ↓
Hook Events → Hook Scripts → SQLite Database → File Backups
    ↓              ↓              ↓                ↓
Tool Usage    Progress      Analytics      User Visibility
Tracking      Monitoring    Queries        & Debugging
```

## Hook Types

### 1. Tool Usage Tracking (`tool-usage-hook.sh`)
Tracks every tool invocation by agents:
- **Events**: `tool.before`, `tool.after`, `tool.error`
- **Captures**: Tool name, parameters, duration, success/failure, result summary
- **Benefits**: Performance analysis, error patterns, optimization opportunities

### 2. Progress Tracking (`progress-hook.sh`)
Monitors agent progress through tasks:
- **Events**: `task.start`, `milestone.reached`, `deliverable.created`, `task.complete`, `task.blocked`
- **Captures**: Task progress, milestones, deliverables, blockers
- **Benefits**: Real-time progress visibility, bottleneck identification

### 3. Error Recovery (`error-recovery-hook.sh`)
Captures and attempts to recover from errors:
- **Events**: `error.captured`, `error.recovered`
- **Captures**: Error type, message, context, recovery attempts
- **Benefits**: Pattern detection, automatic recovery, capability gap identification

## Installation

```bash
# Run from project root
cd hooks
./setup-hooks.sh

# This will:
# 1. Create SQLite tables for hook data
# 2. Install hook scripts to ~/.claude/hooks/
# 3. Create backup directories
# 4. Set up monitoring tools
```

## Configuration

The hook system is configured via `~/.claude/hooks/config.json`:

```json
{
  "hooks": [
    {
      "name": "tool-usage-tracking",
      "script": "tool-usage-hook.sh",
      "events": ["tool.before", "tool.after", "tool.error"],
      "enabled": true
    }
  ],
  "global_settings": {
    "storage_backend": "sqlite",
    "backup_to_files": true,
    "sensitive_data_masking": true
  }
}
```

## Data Storage

### SQLite Tables

1. **hook_tool_usage** - All tool invocations
2. **hook_progress_events** - Task progress and milestones  
3. **hook_error_events** - Errors and recovery attempts
4. **hook_success_events** - Successful completions
5. **hook_agent_sessions** - Agent work sessions

### File Backups

Automatic backups to:
- `~/.claude/agent-tracking-backup/tool-usage.log`
- `~/.claude/agent-progress-backup/Agent-{Name}-progress.log`
- `~/.claude/agent-tracking-backup/errors.log`

## Monitoring Tools

### Real-time Dashboard
```bash
~/.claude/hooks/agent-dashboard.sh
```

Shows:
- Active agent sessions
- Tool usage statistics
- Task progress bars
- Recent errors
- Missing capabilities

### Simple Monitor
```bash
~/.claude/hooks/monitor-agents.sh
```

Basic tabular view of agent activity.

## Usage Examples

### Testing Hooks
```bash
# Test all hooks
~/.claude/hooks/test-hooks.sh

# Test individual hook
CLAUDE_AGENT_ID="test" \
CLAUDE_TOOL_NAME="Read" \
bash ~/.claude/hooks/tool-usage-hook.sh test
```

### Querying Hook Data

```sql
-- Most used tools by agent
SELECT agent_id, tool_name, COUNT(*) as uses
FROM hook_tool_usage
GROUP BY agent_id, tool_name
ORDER BY uses DESC;

-- Error patterns
SELECT error_type, COUNT(*) as occurrences
FROM hook_error_events
WHERE datetime(timestamp) > datetime('now', '-1 day')
GROUP BY error_type;

-- Task completion times
SELECT 
    agent_id,
    task_id,
    (julianday(MAX(timestamp)) - julianday(MIN(timestamp))) * 24 as hours
FROM hook_progress_events
GROUP BY agent_id, task_id
HAVING MAX(CASE WHEN event_type = 'task_complete' THEN 1 ELSE 0 END) = 1;
```

## Slack Integration

The hook system includes comprehensive Slack integration for real-time notifications:

### Setup
```bash
# Configure Slack webhook
~/.claude/hooks/slack-notifier.sh configure

# Test connection
~/.claude/hooks/slack-notifier.sh test

# Start monitoring daemon
~/.claude/hooks/slack-notifier.sh monitor &
```

### Notification Types
- **Critical Alerts**: System failures, critical errors
- **High Priority**: Blocked tasks, missing capabilities
- **Medium Priority**: Completions, milestones, tool errors
- **Low Priority**: Progress updates, recoveries

### Features
- Batched notifications to prevent spam
- Rate limiting
- Performance alerts
- Daily summaries
- Custom notification levels

See [Slack Integration Guide](./SLACK-INTEGRATION-GUIDE.md) for detailed setup.

## Integration with Agent System

### Automatic Capability Detection
When agents encounter errors, the hooks automatically:
1. Detect missing tools/commands
2. Record in `missing_capabilities` table
3. Propose installation solutions
4. Track resolution attempts
5. Send Slack alerts for missing capabilities

### Progress Synchronization
Hooks update both:
- Main task tracking tables
- Progress event tables
- File-based logs for visibility
- Slack notifications for milestones

### Error Recovery Flow
1. Error captured by hook
2. Recovery strategy determined
3. Missing capability recorded if needed
4. Recovery attempted if possible
5. Pattern analysis for recurring issues
6. Slack alerts for critical errors

## Benefits

1. **Complete Visibility**
   - Every agent action tracked
   - No "black box" operations
   - Full audit trail

2. **Performance Optimization**
   - Identify slow tools
   - Find inefficient patterns
   - Optimize based on data

3. **Automatic Problem Resolution**
   - Detect missing capabilities
   - Attempt recovery
   - Learn from patterns

4. **Real-time Monitoring**
   - Live dashboards
   - Progress tracking
   - Instant error alerts

5. **Historical Analysis**
   - Performance trends
   - Error patterns
   - Success metrics

## Troubleshooting

### Hooks Not Firing
1. Check Claude Code hook configuration
2. Verify scripts are executable: `chmod +x ~/.claude/hooks/*.sh`
3. Test manually with test script

### Database Errors
1. Check database exists: `ls ~/.claude/agent-memory/`
2. Verify tables: `sqlite3 ~/.claude/agent-memory/agent-collaboration.db ".tables"`
3. Run setup again if needed

### Missing Data
1. Check backup files in `~/.claude/agent-tracking-backup/`
2. Verify hook scripts have correct paths
3. Check for permission issues

## Advanced Features

### Custom Hooks
Create your own hooks by:
1. Adding script to `~/.claude/hooks/`
2. Updating `config.json`
3. Handling Claude Code events

### Export Data
```bash
# Export to CSV
sqlite3 -header -csv ~/.claude/agent-memory/agent-collaboration.db \
  "SELECT * FROM hook_tool_usage" > tool_usage_export.csv

# Create daily reports
./hooks/generate-daily-report.sh
```

### Integration with CI/CD
Hooks can trigger:
- Build notifications
- Deployment tracking
- Performance alerts
- Error escalation

## Future Enhancements

1. **Machine Learning Integration**
   - Predict task completion times
   - Identify optimal tool sequences
   - Suggest performance improvements

2. **Advanced Analytics**
   - Agent efficiency scoring
   - Collaboration effectiveness
   - Resource utilization

3. **Automated Optimization**
   - Tool parameter tuning
   - Workflow optimization
   - Agent load balancing

The Claude Code hooks system transforms agent operations from opaque processes into fully observable, measurable, and optimizable workflows!