# Orchestration Execution Model & Progress Tracking

## How Parallel Execution Works in Claude Code

### Current Execution Model

Claude Code operates as a **single-threaded instance** with sequential tool execution. When the orchestration agent "runs" multiple agents:

1. **Sequential Simulation**: Agents are called one after another, not truly in parallel
2. **Context Switching**: Claude simulates different agent personas by switching prompts
3. **Shared Context**: All agents share the same Claude instance and memory
4. **No Background Processing**: Once Claude responds, it waits for the next user input

### Simulated Parallelism

The orchestration agent creates the *illusion* of parallel execution by:

```yaml
Phase 1: Analysis (appears parallel, but sequential)
  ├─ Call business-analyst agent
  ├─ Then call competitive-intelligence-expert
  └─ Then call product-strategy-expert
  
Phase 2: Design (dependent on Phase 1)
  ├─ Call uiux-expert with Phase 1 results
  └─ Call database-architect with Phase 1 results
```

### True Parallelism Options

For actual parallel execution, you would need:

1. **Multiple Claude Instances**: Run separate Claude Code windows
2. **External Orchestration**: Use a script to coordinate multiple Claude API calls
3. **MCP Server Orchestration**: Build an MCP server that manages parallel tasks

## Progress Tracking System

### 1. Orchestration Plan File

Create `~/.claude/agent-workspaces/orchestration-plan.md`:

```markdown
# Orchestration Plan: [Project Name]
Generated: 2024-01-20 10:30:00
Status: IN_PROGRESS
Level: 3 (Alpha Production)

## Project Overview
Building a SaaS pricing optimization tool with ML capabilities

## Execution Plan

### Phase 1: Research & Analysis (0/3 completed)
- [ ] **business-analyst**: Market research and competitor analysis
  - Status: IN_PROGRESS
  - Started: 10:31:00
  - Dependencies: None
  - Estimated: 15 minutes
  
- [ ] **competitive-intelligence-expert**: Pricing model analysis
  - Status: PENDING
  - Dependencies: None
  - Estimated: 20 minutes
  
- [ ] **data-analytics-expert**: Historical pricing data analysis
  - Status: PENDING  
  - Dependencies: None
  - Estimated: 10 minutes

### Phase 2: Architecture & Design (0/2 completed)
- [ ] **product-strategy-expert**: Define MVP features
  - Status: WAITING
  - Dependencies: Phase 1 completion
  - Estimated: 15 minutes
  
- [ ] **uiux-expert**: Design pricing dashboard
  - Status: WAITING
  - Dependencies: product-strategy-expert
  - Estimated: 30 minutes

### Phase 3: Implementation (0/4 completed)
- [ ] **database-architect**: Design schema for pricing data
- [ ] **backend-expert**: API development
- [ ] **frontend-expert**: Dashboard implementation  
- [ ] **ai-ml-expert**: Pricing optimization model

### Phase 4: Quality & Deployment (0/3 completed)
- [ ] **qa-test-engineer**: Test suite development
- [ ] **security-specialist**: Security audit
- [ ] **devops-sre-expert**: Deployment pipeline

## Progress Metrics
- Total Agents: 12
- Completed: 0
- In Progress: 1
- Estimated Total Time: 4 hours
- Elapsed Time: 5 minutes

## Key Decisions Made
- None yet

## Blockers & Issues
- None yet
```

### 2. Real-time Status Updates

Create `agents/orchestration-progress-tracker.md`:

```markdown
---
name: orchestration-progress-tracker
description: Tracks and reports orchestration progress
---

## Progress Tracking Responsibilities

### Status File Management
Update `orchestration-plan.md` after each agent completes:
1. Mark task as completed with timestamp
2. Add key findings to "Key Decisions Made"
3. Update progress metrics
4. Note any blockers

### Status Visualization
Create ASCII progress bars:
```
Phase 1: Research    [████████░░░░░░░] 53% (2/3 agents)
Phase 2: Design      [░░░░░░░░░░░░░░░] 0% (waiting)
Phase 3: Implement   [░░░░░░░░░░░░░░░] 0% (waiting)
Phase 4: Deploy      [░░░░░░░░░░░░░░░] 0% (waiting)
Overall Progress:    [███░░░░░░░░░░░░] 17% (2/12 agents)
```

### Timeline Logging
Maintain `orchestration-timeline.jsonl` for debugging:
```json
{"timestamp": "2024-01-20T10:31:00Z", "event": "agent_start", "agent": "business-analyst", "phase": 1}
{"timestamp": "2024-01-20T10:31:05Z", "event": "decision", "agent": "business-analyst", "decision": "Focus on B2B SaaS market"}
{"timestamp": "2024-01-20T10:45:00Z", "event": "agent_complete", "agent": "business-analyst", "duration": "14m", "status": "success"}
{"timestamp": "2024-01-20T10:45:01Z", "event": "agent_start", "agent": "competitive-intelligence-expert", "phase": 1}
```
```

### 3. Project Level Configuration

Create `agents/project-level-config.json`:

```json
{
  "levels": {
    "1": {
      "name": "MVP/Prototype",
      "description": "Basic functionality, proof of concept",
      "characteristics": {
        "code_quality": "prototype",
        "testing": "minimal",
        "documentation": "basic",
        "security": "basic",
        "scalability": "single-user",
        "ui_polish": "functional"
      },
      "agent_instructions": {
        "focus": "speed and functionality",
        "skip": ["performance optimization", "extensive testing", "production security"],
        "time_allocation": "minimize"
      }
    },
    "2": {
      "name": "Beta/Development",
      "description": "Feature complete but not production ready",
      "characteristics": {
        "code_quality": "clean",
        "testing": "basic unit tests",
        "documentation": "developer docs",
        "security": "standard",
        "scalability": "small team",
        "ui_polish": "consistent"
      }
    },
    "3": {
      "name": "Alpha Production",
      "description": "Production ready for early adopters",
      "characteristics": {
        "code_quality": "production",
        "testing": "comprehensive",
        "documentation": "user and developer docs",
        "security": "hardened",
        "scalability": "hundreds of users",
        "ui_polish": "polished"
      }
    },
    "4": {
      "name": "Production Ready",
      "description": "Ready for general availability",
      "characteristics": {
        "code_quality": "optimized",
        "testing": "full coverage + integration",
        "documentation": "complete",
        "security": "audited",
        "scalability": "thousands of users",
        "ui_polish": "professional"
      }
    },
    "5": {
      "name": "Enterprise Ready",
      "description": "Ready for enterprise deployment",
      "characteristics": {
        "code_quality": "enterprise standards",
        "testing": "full coverage + performance + security",
        "documentation": "comprehensive + compliance",
        "security": "enterprise grade + compliance",
        "scalability": "unlimited with HA",
        "ui_polish": "white-label ready",
        "additional": ["SLA support", "audit logs", "RBAC", "SSO", "compliance certs"]
      }
    }
  }
}
```

### 4. Interactive Orchestration Mode

Update `agents/orchestration-agent.md` to add interactive mode:

```markdown
## Interactive Mode

When `interactive_mode: true` is set, I will:

### Pre-Execution Questions
1. **Project Understanding**
   - "What is the primary goal of this project?"
   - "Who is the target audience?"
   - "What is your timeline?"
   - "What is your budget constraint?"

2. **Technical Preferences**
   - "Do you have a preferred tech stack?"
   - "Any existing systems to integrate with?"
   - "Hosting preferences (cloud provider)?"

3. **Quality Requirements**
   - "What project level are you targeting? (1-5)"
   - "Any specific compliance requirements?"
   - "Performance requirements?"

### Mid-Execution Checkpoints
After each phase, ask:
1. "The research phase revealed [findings]. Should we adjust our approach?"
2. "Based on complexity, this will take [time]. Continue or simplify?"
3. "We found [unexpected issue]. How would you like to proceed?"

### Decision Points
Present options at critical junctures:
```yaml
Decision Required: Database Technology
Context: High write volume expected (10k/sec)
Options:
  A. PostgreSQL with optimization (reliable, moderate complexity)
  B. Cassandra (high performance, higher complexity)  
  C. DynamoDB (managed service, vendor lock-in)
Recommendation: A (PostgreSQL) for balance of performance and maintainability
Your choice?
```

### Progressive Disclosure
Ask follow-up questions as new information emerges:
- Initial: "Do you need real-time features?"
- If yes: "What's your latency requirement?"
- Follow-up: "How many concurrent users?"
```

## Implementation Examples

### 1. Starting Orchestration with Progress Tracking

```javascript
// orchestration-agent starts a complex task
async function startOrchestration(project, level = 3, interactive = false) {
  // Create initial plan
  const plan = await createOrchestrationPlan(project, level);
  await writeFile('orchestration-plan.md', plan);
  
  // Initialize timeline
  await appendToTimeline({
    event: 'orchestration_start',
    project,
    level,
    interactive,
    total_agents: plan.totalAgents
  });
  
  if (interactive) {
    // Ask initial questions
    const responses = await askProjectQuestions();
    plan.context = responses;
  }
  
  // Execute phases
  for (const phase of plan.phases) {
    await executePhase(phase);
  }
}
```

### 2. Progress Monitoring Script

Create `~/.claude/scripts/monitor-progress.sh`:

```bash
#!/bin/bash
# Monitor orchestration progress

WORKSPACE="$HOME/.claude/agent-workspaces"
PLAN_FILE="$WORKSPACE/orchestration-plan.md"

while true; do
  clear
  echo "🎭 ORCHESTRATION PROGRESS MONITOR"
  echo "================================="
  echo ""
  
  if [ -f "$PLAN_FILE" ]; then
    # Extract progress
    grep -E "^- \[.\]" "$PLAN_FILE" | while read line; do
      if [[ $line == *"[x]"* ]]; then
        echo "✅ $line"
      elif [[ $line == *"IN_PROGRESS"* ]]; then
        echo "🔄 $line"
      else
        echo "⏳ $line"
      fi
    done
    
    echo ""
    echo "Summary:"
    grep "Progress Metrics" -A 5 "$PLAN_FILE"
  else
    echo "No active orchestration found."
  fi
  
  sleep 5
done
```

### 3. Debug Timeline Viewer

Create `~/.claude/scripts/view-timeline.py`:

```python
#!/usr/bin/env python3
import json
import sys
from datetime import datetime

def view_timeline(file_path):
    """View orchestration timeline in human-readable format"""
    
    with open(file_path, 'r') as f:
        events = [json.loads(line) for line in f]
    
    print("🕐 ORCHESTRATION TIMELINE")
    print("=" * 60)
    
    start_time = None
    for event in events:
        timestamp = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00'))
        
        if not start_time:
            start_time = timestamp
            elapsed = "00:00"
        else:
            elapsed_seconds = (timestamp - start_time).total_seconds()
            elapsed = f"{int(elapsed_seconds//60):02d}:{int(elapsed_seconds%60):02d}"
        
        event_type = event['event']
        
        if event_type == 'agent_start':
            print(f"[{elapsed}] ▶️  Starting {event['agent']}")
        elif event_type == 'agent_complete':
            print(f"[{elapsed}] ✅ Completed {event['agent']} ({event.get('duration', 'N/A')})")
        elif event_type == 'decision':
            print(f"[{elapsed}] 💡 Decision: {event['decision']}")
        elif event_type == 'blocker':
            print(f"[{elapsed}] 🚫 Blocker: {event['description']}")
        elif event_type == 'user_input':
            print(f"[{elapsed}] ❓ User Input: {event['question']}")
            print(f"[{elapsed}] 💬 Response: {event['response']}")

if __name__ == "__main__":
    timeline_file = sys.argv[1] if len(sys.argv) > 1 else "~/.claude/agent-workspaces/orchestration-timeline.jsonl"
    view_timeline(timeline_file)
```

## Timeout Feature

### How Timeouts Work

When in interactive mode, the orchestration agent will:
1. Present options with a clear recommendation
2. Start a countdown timer (default 5 minutes)
3. Show visual progress of time remaining
4. Auto-proceed with the recommendation if no response

### Timeout Configuration

Timeouts are dynamically calculated based on:

```javascript
timeout = base_timeout * level_multiplier * timeline_multiplier
```

Examples:
- **Level 1 MVP + Urgent timeline**: 2 min * 0.4 * 0.4 = ~1 minute
- **Level 3 Alpha + Normal timeline**: 5 min * 1.0 * 1.0 = 5 minutes  
- **Level 5 Enterprise + Relaxed**: 10 min * 2.0 * 2.0 = 20 minutes (capped)

### Special Cases

Critical decisions get extended timeouts:
- Database selection: 10 minutes
- Security decisions: 15 minutes
- Cost-impacting choices: 10 minutes
- API design: 8 minutes

### Visual Feedback

```
⏱️ Auto-proceeding with option B in 5 minutes...
[████████████░░░░░░░░░░░] 2:34 remaining

Warning at 1 minute:
⚠️ 60 seconds until auto-proceed

Warning at 30 seconds:
⚠️ 30 seconds until auto-proceed - respond now!

On timeout:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️ TIMEOUT: Auto-proceeding with recommended option
Decision: B - Modular Monolith
Reason: No user response within 5 minute timeout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Disabling Timeouts

Users can disable auto-proceed:
- Set `auto_proceed: false` in project config
- Use `timeout: none` for specific decisions
- Switch to `fully_autonomous` mode

## Best Practices

### 1. Status Communication
- Update progress file every 2-3 minutes
- Use clear status indicators (emojis help)
- Include time estimates and actual durations
- Note key decisions and blockers

### 2. Level-Appropriate Execution
- Level 1: Skip non-essential agents, focus on core functionality
- Level 2-3: Include testing and documentation agents
- Level 4-5: Full agent suite with security and compliance

### 3. Interactive Mode Guidelines
- Ask questions that materially affect the outcome
- Provide clear context for decisions
- Offer sensible defaults
- Allow "auto-pilot" option to continue without interaction
- Auto-proceed with recommendations after timeout
- Timeout duration based on decision criticality and project level

### 4. Debug Information
- Log all agent calls and responses
- Track decision rationale
- Record performance metrics
- Enable replay for learning

## Future Enhancements

### 1. True Parallel Execution
- MCP orchestration server that spawns multiple Claude instances
- External Python/Node orchestrator using Claude API
- Webhook-based agent coordination

### 2. Real-time Dashboard
- Web-based progress viewer
- Live timeline visualization
- Agent dependency graph
- Resource utilization metrics

### 3. Learning System
- Analyze successful orchestrations
- Optimize agent selection
- Improve time estimates
- Suggest process improvements