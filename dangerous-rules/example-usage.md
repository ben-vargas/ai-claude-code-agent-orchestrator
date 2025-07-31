# Example Usage of Dangerous Rules

## ⚠️ FOR DEMONSTRATION ONLY - DO NOT USE IN PRODUCTION ⚠️

This document shows how these dangerous rules might be used in **controlled environments only**.

## 1. Setting Up an Isolated Environment

### Option A: Virtual Machine
```bash
# Create a disposable VM
vagrant init ubuntu/jammy64
vagrant up
vagrant ssh

# Inside VM, install Claude Code
# Copy rules to isolated config
mkdir -p ~/.claude-test/rules
cp /vagrant/dangerous-rules/permissive-dev-rules.json ~/.claude-test/rules/
```

### Option B: Docker Container
```bash
# Run Claude Code in Docker with isolated filesystem
docker run -it --rm \
  -v $(pwd)/dangerous-rules:/rules:ro \
  -v /tmp/claude-workspace:/workspace \
  --name claude-dangerous \
  claude-code:latest
```

### Option C: Cloud Workspace
Use a disposable cloud workspace that can be destroyed after testing.

## 2. Using Rules with Claude Code

### For Development Testing
```bash
# Set alternate config directory
export CLAUDE_CONFIG_DIR=~/.claude-test

# Copy specific rules
cp dangerous-rules/permissive-dev-rules.json $CLAUDE_CONFIG_DIR/rules/

# Run Claude Code with dangerous rules
claude --rules permissive-dev-rules
```

### For Automation Testing
```bash
# Use automation rules for CI/CD testing
claude --rules automation-rules --project ./test-project

# Example: Automated build and deploy
claude "Build and deploy the application to staging"
# Agent will proceed without any confirmations
```

### For Research Projects
```bash
# Use research rules for data analysis
claude --rules research-rules --workspace ./research

# Example: Data collection and analysis
claude "Analyze all log files and create visualizations"
# Agent will have broad read access and processing capabilities
```

## 3. Multi-Agent Orchestration Example

```bash
# Use orchestration rules for complex projects
claude --rules orchestration-rules

# Example prompt:
claude "Create a full-stack application with authentication, 
        deploy to AWS, and set up monitoring"

# The orchestration agent will:
# 1. Spawn multiple specialized agents
# 2. Distribute tasks automatically
# 3. Coordinate without confirmations
# 4. Deploy without human intervention
```

## 4. Safety Measures Even with Dangerous Rules

### Pre-execution Checklist
- [ ] Running in isolated environment
- [ ] All important data backed up
- [ ] No production credentials accessible
- [ ] Network access limited if needed
- [ ] Monitoring/logging enabled
- [ ] Kill switch ready (Ctrl+C)

### Monitoring Commands
```bash
# Watch what files are being modified
watch -n 1 'find . -mmin -5 -type f'

# Monitor process activity
htop

# Track network connections
netstat -tulpn

# View audit log (if enabled)
tail -f ~/.claude-test/audit.log
```

### Emergency Stop
```bash
# Kill all Claude processes
pkill -f claude

# Revoke permissions immediately
rm -rf ~/.claude-test/rules/

# Check for remaining processes
ps aux | grep claude
```

## 5. Rule Customization

You can create custom rules by modifying the templates:

```json
{
  "name": "My Custom Rules",
  "description": "Customized for specific project",
  "rules": {
    "file_operations": {
      "delete": {
        "enabled": true,
        "require_confirmation": false,
        "allowed_paths": [
          "/my/specific/project/**"
        ]
      }
    }
  }
}
```

## 6. Reverting to Safe Mode

After testing with dangerous rules:

```bash
# Remove dangerous rules
rm -rf $CLAUDE_CONFIG_DIR/rules/

# Reset to default configuration
unset CLAUDE_CONFIG_DIR

# Verify safe mode
claude --show-rules
```

## 7. Logging and Auditing

Even with permissive rules, maintain audit trails:

```bash
# Enable audit logging
export CLAUDE_AUDIT_LOG=/tmp/claude-audit.log

# Run with dangerous rules
claude --rules permissive-dev-rules "Perform task"

# Review audit log
cat $CLAUDE_AUDIT_LOG | jq '.operations[] | select(.risk == "high")'
```

## Remember

These rules are **DANGEROUS BY DESIGN**. They exist to show what's possible in controlled environments, not what should be done in real systems.

**Never use these rules on:**
- Your personal computer
- Production systems  
- Systems with important data
- Shared environments
- Internet-connected systems

**Always use these rules with:**
- Isolated environments
- Disposable systems
- Full backups
- Monitoring active
- Clear understanding of risks