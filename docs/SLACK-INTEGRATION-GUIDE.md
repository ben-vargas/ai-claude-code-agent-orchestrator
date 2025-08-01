# Slack Integration Guide for Claude Code Hooks

## Overview

The Claude Code hooks system includes comprehensive Slack integration for real-time notifications of agent activities, errors, milestones, and performance alerts. This guide walks you through setting up and configuring Slack notifications.

## Prerequisites

1. A Slack workspace where you have permission to create webhooks
2. Claude Code hooks installed (`cd hooks && ./setup-hooks.sh`)
3. SQLite database initialized with agent tracking tables

## Setting Up Slack Webhook

### Step 1: Create Incoming Webhook

1. Go to [Slack API Apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. Name your app (e.g., "Claude Code Agent Monitor")
4. Select your workspace
5. Navigate to "Incoming Webhooks" in the sidebar
6. Toggle "Activate Incoming Webhooks" to ON
7. Click "Add New Webhook to Workspace"
8. Select the channel for notifications (e.g., #agent-monitoring)
9. Copy the webhook URL (looks like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`)

### Step 2: Configure Claude Code Hooks

Run the configuration script:

```bash
~/.claude/hooks/slack-notifier.sh configure
```

Enter:
- Your webhook URL
- Channel name (optional - uses webhook default)
- Notification level:
  - **All events**: Every agent action
  - **Important only** (recommended): Completions, errors, milestones
  - **Errors only**: Only failures and critical issues

### Step 3: Test Connection

```bash
~/.claude/hooks/slack-notifier.sh test
```

You should see a test message in your Slack channel.

## Notification Types

### Critical Alerts (🚨)
Immediate notifications for:
- Critical errors
- System failures
- Security issues
- Resource exhaustion

### High Priority (⚠️)
- Task blockages
- Missing capabilities
- Performance degradation
- Recurring error patterns

### Medium Priority (ℹ️)
- Task completions
- Milestone achievements
- Tool errors
- Deliverable creation

### Low Priority (✅)
- Progress updates
- Successful recoveries
- Routine completions

## Configuration Options

### Notification Levels

Edit `~/.claude/hooks/slack-config.json`:

```json
{
  "webhook_url": "https://hooks.slack.com/services/...",
  "channel": "#agent-monitoring",
  "notification_level": "important",
  "batch_interval": 30,
  "rate_limit": 10
}
```

- **notification_level**:
  - `"all"`: Every event
  - `"important"`: Milestones, completions, errors
  - `"errors_only"`: Only failures

- **batch_interval**: Seconds between batched notifications (default: 30)
- **rate_limit**: Max messages per minute (default: 10)

### Custom Channels

You can override the default channel per notification type:

```bash
# In your scripts
SLACK_CHANNEL="#critical-alerts" notify_slack "error.critical" ...
```

## Running the Monitor

### Continuous Monitoring

Start the Slack monitoring daemon:

```bash
~/.claude/hooks/slack-notifier.sh monitor &
```

This will:
- Process queued notifications every 30 seconds
- Check for performance issues every 5 minutes
- Send alerts for stuck tasks
- Monitor error rates

### Daily Summaries

Get daily agent activity summaries:

```bash
# Manual summary
~/.claude/hooks/slack-notifier.sh summary

# Or schedule with cron
0 18 * * * ~/.claude/hooks/slack-notifier.sh summary
```

## Notification Examples

### Task Completion
```
✅ backend-expert completed task (duration:45m)
```

### Error Detection
```
❌ frontend-expert tool error: Tool: npm - Error: ENOENT: no such file or directory
```

### Missing Capability
```
⚠️ database-architect missing capability: Missing: psql (Strategy: install_tool)
```

### Milestone Reached
```
🎯 ai-ml-expert reached milestone: Model Training Complete (80%)
```

### Critical Alert
```
🚨 Critical Alert
Critical Error: system_failure - Database connection lost
_2024-01-15 10:32:45_
```

### Performance Alert
```
⚠️ Performance Alert
Error rate is at 25.3% in the last 5 minutes
```

## Advanced Features

### Custom Notifications

Add custom notifications in your hooks:

```bash
# In your hook script
source "$(dirname "$0")/slack-integration.sh"

# Send custom notification
notify_slack "custom.event" "agent-name" "Custom message" "medium"

# Send critical alert
alert_slack "agent-name" "Critical custom event occurred!"
```

### Filtering Notifications

Create filters in `slack-notifier.sh`:

```bash
# Add to should_notify() function
case "$event_type" in
    "my.custom.event")
        [ "$NOTIFICATION_LEVEL" = "all" ] && return 0
        ;;
esac
```

### Multiple Workspaces

Configure multiple Slack workspaces:

```bash
# Create separate configs
cp ~/.claude/hooks/slack-config.json ~/.claude/hooks/slack-config-dev.json
cp ~/.claude/hooks/slack-config.json ~/.claude/hooks/slack-config-prod.json

# Use environment variable
SLACK_CONFIG=~/.claude/hooks/slack-config-prod.json \
  ~/.claude/hooks/slack-notifier.sh notify ...
```

## Troubleshooting

### No Notifications Received

1. Check webhook URL is correct:
   ```bash
   jq '.webhook_url' ~/.claude/hooks/slack-config.json
   ```

2. Test webhook directly:
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test message"}' \
     YOUR_WEBHOOK_URL
   ```

3. Check hook scripts are sourcing Slack integration:
   ```bash
   grep "slack-integration.sh" ~/.claude/hooks/*.sh
   ```

### Too Many Notifications

Adjust notification level:
```bash
~/.claude/hooks/slack-notifier.sh configure
# Choose "important" or "errors_only"
```

Or increase batch interval:
```bash
jq '.batch_interval = 120' ~/.claude/hooks/slack-config.json > tmp.json
mv tmp.json ~/.claude/hooks/slack-config.json
```

### Missing Notifications

Check if notifications are queued:
```bash
jq '.messages | length' ~/.claude/hooks/slack-queue.json
```

Process queue manually:
```bash
~/.claude/hooks/slack-notifier.sh process
```

### Performance Issues

Monitor the monitoring daemon:
```bash
ps aux | grep slack-notifier
```

Check database for bottlenecks:
```bash
sqlite3 ~/.claude/agent-memory/agent-collaboration.db \
  "SELECT COUNT(*) FROM hook_tool_usage WHERE datetime(hook_timestamp) > datetime('now', '-1 hour')"
```

## Best Practices

1. **Start with "important" level** - Provides good signal-to-noise ratio
2. **Use dedicated channel** - Keep agent notifications separate
3. **Monitor rate limits** - Slack has webhook rate limits
4. **Archive old notifications** - Slack channels can get cluttered
5. **Set up alerts** - Use Slack's notification settings for critical alerts
6. **Regular summaries** - Daily summaries provide better overview than constant updates

## Integration with CI/CD

Add to your deployment scripts:

```bash
# Notify deployment start
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"🚀 Deployment started by orchestration-agent"}' \
  $SLACK_WEBHOOK_URL

# After deployment
if [ $? -eq 0 ]; then
  notify_slack "deployment.success" "orchestration-agent" "Deployment completed successfully" "medium"
else
  alert_slack "orchestration-agent" "Deployment failed! Check logs."
fi
```

## Security Considerations

1. **Never commit webhook URLs** - Keep them in environment variables
2. **Rotate webhooks regularly** - Regenerate if compromised
3. **Limit channel access** - Only authorized users should see agent activity
4. **Mask sensitive data** - Hooks already mask passwords, tokens, etc.
5. **Use private channels** - For sensitive agent operations

## Next Steps

1. Configure Slack webhook
2. Set appropriate notification level
3. Start monitoring daemon
4. Customize notifications for your workflow
5. Set up daily summaries
6. Create custom alerts for your specific needs

The Slack integration transforms agent monitoring from checking logs to receiving actionable real-time insights!