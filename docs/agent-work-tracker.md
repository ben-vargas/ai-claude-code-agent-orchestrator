# Agent Work Tracking System

## Overview

This document defines how agents track their work, communicate with other agents, and suggest improvements to the system.

## Work Tracking Protocol

### 1. Task Initiation

When an agent receives a task:
1. Generate unique task ID: `{AGENT_PREFIX}-{YYYYMMDD}-{SEQUENCE}`
2. Create/update their Agent-{Name}.md file in `.claude/agent-workspaces/`
3. Log task initiation with initiator details
4. Estimate completion time

### 2. During Work

Agents should:
- Update progress percentage every 25% milestone
- Log significant discoveries or blockers immediately
- Track all tools and MCPs used
- Note any agents consulted
- Document deliverable locations

### 3. Task Completion

Upon completion:
1. Generate standardized output JSON (per agent-output-schema.json)
2. Update Agent-{Name}.md with completion details
3. Calculate actual duration
4. Suggest follow-up agents if needed
5. Archive to task history

### 4. Suggesting New Agents

Agents can suggest new specialized agents by:
1. Identifying repeated patterns needing expertise
2. Documenting the gap in current capabilities
3. Proposing the new agent's core competencies
4. Estimating frequency of need

Format:
```json
{
  "suggestedAgent": "specialized-expert-name",
  "reason": "Specific capability gap identified",
  "coreCompetencies": ["skill1", "skill2"],
  "estimatedUsageFrequency": "daily|weekly|monthly",
  "exampleUseCases": ["case1", "case2"]
}
```

### 5. Tool/MCP Suggestions

When agents identify missing tools:
1. Document what task is difficult/impossible without the tool
2. Specify desired functionality
3. Indicate if it's blocking work
4. Suggest alternatives if known

Format:
```json
{
  "suggestedTool": "tool-name",
  "purpose": "What it would enable",
  "currentWorkaround": "How task is done now",
  "timesSaved": "Estimated efficiency gain",
  "priority": "critical|high|medium|low"
}
```

## Inter-Agent Communication

### Handoff Protocol

When passing work between agents:
1. Creating agent finalizes their output
2. Specifies next agent(s) and why
3. Includes context and deliverables
4. Sets priority and any deadlines
5. Receiving agent acknowledges receipt

### Parallel Coordination

For parallel work:
1. Orchestration agent creates coordination ID
2. All parallel agents reference this ID
3. Regular sync points defined
4. Merge strategy specified upfront

### Feedback Loops

Agents should:
1. Report back on handoff quality
2. Suggest process improvements
3. Rate collaboration effectiveness
4. Identify communication gaps

## Agent Workspace File Structure

Each agent maintains: `.claude/agent-workspaces/Agent-{AgentName}.md`

Examples:
- `Agent-Frontend.md` for frontend-expert
- `Agent-Backend.md` for backend-expert
- `Agent-DevOps.md` for devops-sre-expert
- `Agent-Orchestration.md` for orchestration-agent
- `Agent-ProductStrategy.md` for product-strategy-expert

Sections:
1. **Header**: Agent info and current status
2. **Current Tasks**: In-progress work with checklists
3. **Completed Tasks**: Recent completions with outcomes
4. **Blocked Tasks**: Items needing resolution
5. **Agent Suggestions**: Proposed new agents/improvements
6. **Tool Suggestions**: Needed tools/MCPs
7. **Collaboration Log**: Recent agent interactions
8. **Metrics**: Performance indicators
9. **Notes**: Observations and patterns

## Workspace Organization

```
.claude/
├── agents/                      # Agent definitions
│   ├── *.md                    # Individual agent files
│   ├── agent-registry.json     # Master registry
│   └── agent-output-schema.json # Output format
├── agent-workspaces/           # Active work tracking
│   ├── Agent-*.md             # Per-agent tracking files
│   └── orchestration-log.json  # Master orchestration log
└── agent-archives/             # Completed task archives
    └── {YYYY-MM}/             # Monthly archives
        └── *.json             # Completed task outputs
```

## Best Practices

1. **Update Frequency**: Update Agent-{Name}.md at least every hour during active work
2. **Blocker Escalation**: Report blockers within 15 minutes
3. **Handoff Clarity**: Include all context needed for next agent
4. **Tool Documentation**: Document both what was used and what was missing
5. **Pattern Recognition**: Note repeated tasks that could be automated

## Integration Points

### With Orchestration Agent
- Orchestration agent monitors all Agent-*.md files
- Aggregates suggestions across agents
- Identifies optimization opportunities
- Manages resource allocation

### With Project Management
- Task IDs link to project tracking
- Deliverables reference project structure
- Timelines align with project milestones
- Dependencies mapped to project plan

### With Quality Assurance
- Each deliverable includes quality checklist
- Peer review assignments tracked
- Test results linked to tasks
- Improvement suggestions logged

## Continuous Improvement

Agents should regularly:
1. Review their own efficiency metrics
2. Identify repetitive tasks for automation
3. Suggest process improvements
4. Share successful patterns with other agents
5. Request training or resources needed

This system enables transparent, efficient, and continuously improving agent collaboration.