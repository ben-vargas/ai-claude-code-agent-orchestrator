# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Claude Code Agent Orchestrator - a system of 24 specialized AI agents designed to work together on complex software development tasks. The project provides Claude Code with specialized agent definitions that enable multi-expert collaboration.

## Key Commands

### Installation
```bash
# macOS installation
./install.sh

# Manual installation
cp -r agents/* ~/.claude/agents/
mkdir -p ~/.claude/agent-workspaces
```

### Git Operations
```bash
# The project is already initialized with git and connected to GitHub
# Remote: https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator

# Push changes (already done for initial setup)
git push origin main
```

## Architecture & Agent System

### Core Components

1. **Agent Definitions** (`agents/`):
   - 24 specialized `.md` files defining agent capabilities
   - Each agent follows a standardized YAML frontmatter + prompt format
   - Agents have specific expertise areas and collaboration patterns

2. **Agent Registry** (`agents/agent-registry.json`):
   - Central registry of all agents with metadata
   - Defines expertise areas and collaboration relationships
   - Used by orchestration-agent for task routing

3. **Output Schema** (`agents/agent-output-schema.json`):
   - Standardized JSON format for agent responses
   - Ensures consistent communication between agents

### Agent Categories

- **Engineering**: backend, frontend, mobile, ai-ml, blockchain, performance
- **Strategy**: business-analyst, product-strategy, pricing, competitive-intelligence
- **Infrastructure**: cloud-architect, devops-sre, database-architect
- **Design**: uiux-expert
- **Growth**: marketing, social-media, customer-success
- **Operations**: business-operations, legal-compliance, data-analytics
- **Security**: security-specialist, cloud-security-auditor
- **Quality**: qa-test-engineer
- **Coordination**: orchestration-agent (meta-agent)

### How Agents Work

1. **Selection**: Claude Code automatically selects appropriate agents based on user requests
2. **Orchestration**: For complex tasks, orchestration-agent coordinates multiple specialists
3. **Collaboration**: Agents follow defined collaboration patterns for efficient workflows
4. **Output**: All agents produce standardized JSON outputs for interoperability

### Key Workflows

**Single Agent Tasks**:
- Direct routing to specialist when domain is clear
- Agent handles task independently
- Returns structured output

**Multi-Agent Orchestration**:
- Orchestration-agent decomposes complex projects
- Identifies dependencies and parallel execution paths
- Coordinates agent collaboration
- Tracks progress across all agents

**Multi-Agent Evaluation**:
- Same task sent to multiple agents for comparison
- Performance tracking and learning
- Optimal agent selection refinement

## Project Structure

```
Claude-Code-Agent-Orchestrator/
├── agents/                    # Agent definitions and registry
│   ├── *.md                  # Individual agent definition files
│   ├── agent-registry.json   # Central agent registry
│   └── agent-output-schema.json # Standardized output format
├── docs/                     # Documentation
├── windows/                  # Windows installation files
├── install.sh               # macOS installation script
└── README.md               # Main documentation
```

## Agent Communication Protocol

Agents communicate using standardized JSON:
```json
{
  "agent": "agent-name",
  "taskId": "unique-id",
  "status": "completed|in-progress|failed",
  "outputs": {
    "deliverables": [],
    "insights": [],
    "metrics": {}
  },
  "suggestedAgents": [],
  "nextSteps": []
}
```

## Work Tracking

Agents maintain progress in `~/.claude/agent-workspaces/Agent-{Name}.md` with:
- Current task status
- Completed deliverables
- Collaboration logs
- Performance metrics

## Important Commands

1. **Check SQLite installation** (macOS):
   ```bash
   sqlite3 --version
   # Should show version 3.x.x
   ```

2. **Manage MCP servers**:
   ```bash
   # Auto-check and copy MCP servers
   ./scripts/mcp-server-manager.sh --auto
   
   # Interactive MCP server management
   ./scripts/mcp-server-manager.sh
   ```

3. **Run main orchestrator**:
   ```bash
   ./scripts/orchestrator.sh "Project Name" 3 true 5
   # Parameters: name, level (1-5), interactive (true/false), timeout (minutes)
   ```

4. **Run parallel orchestrator**:
   ```bash
   ./scripts/parallel-orchestrator.sh "Project Name" 3 4
   # Parameters: name, level (1-5), max terminals
   ```

## MCP Server Integration

The orchestrator now includes automatic MCP server detection and validation:

1. **Installation**: The `install.sh` script automatically runs MCP server checks
2. **Orchestration**: Both orchestrator scripts check MCP servers before starting
3. **Agent-specific**: Individual agents check their required MCP servers
4. **Requirements**: Defined in `agents/mcp-requirements.json`

### Critical MCP Servers
- **filesystem**: Required for file operations
- **memory**: Required for persistent agent memory
- **web**: Recommended for web operations
- **git**: Recommended for version control

### Running Without MCP Servers
If critical MCP servers are missing:
- Installation will warn but continue
- Orchestration will prompt to continue
- Agents will have limited functionality
- Run `./scripts/mcp-server-manager.sh` to fix