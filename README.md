# Claude Code Agent Orchestrator 🎭

A comprehensive system of 24 specialized AI agents that work together to handle complex software development tasks. Built for [Claude Code](https://claude.ai/code) by [W4M.ai](https://w4m.ai).

## 🚀 Overview

Transform your development workflow with specialized AI agents that collaborate like a world-class team. Each agent is an expert in their domain, from backend architecture to pricing strategy, working together under intelligent orchestration.

### Key Features

- **24 Specialized Agents**: Expert knowledge across all development domains
- **Intelligent Orchestration**: Automatic task routing and parallel execution
- **Multi-Agent Evaluation**: Compare approaches from multiple experts
- **Self-Improving System**: Learns optimal agent selection over time
- **Standardized Communication**: Consistent output format for seamless collaboration
- **Work Tracking**: Each agent maintains progress logs and deliverables
- **MCP-Ready Architecture**: Designed for seamless Model Context Protocol integration

## 📋 Available Agents

### Engineering
- `backend-expert` - API development, microservices, databases
- `frontend-expert` - React, Vue, Angular, UI development
- `mobile-expert` - iOS, Android, React Native, Flutter
- `ai-ml-expert` - Machine learning, NLP, computer vision
- `blockchain-expert` - Smart contracts, Web3, DeFi
- `performance-engineer` - Optimization, load testing, profiling

### Strategy & Analysis
- `business-analyst` - Market research, competitive analysis
- `product-strategy-expert` - Product-market fit, roadmaps
- `pricing-optimization-expert` - Dynamic pricing, revenue optimization
- `competitive-intelligence-expert` - Market monitoring, benchmarking

### Infrastructure
- `cloud-architect` - AWS, Azure, infrastructure design
- `devops-sre-expert` - CI/CD, monitoring, deployment
- `database-architect` - Database design, optimization
- `cloud-security-auditor` - Security audits, compliance

### Design & Customer
- `uiux-expert` - User research, wireframing, prototyping
- `customer-success-expert` - Onboarding, retention, support

### Growth & Marketing
- `marketing-expert` - Content, SEO, campaigns
- `social-media-expert` - Social strategy, community

### Operations & Security
- `business-operations-expert` - Payments, billing, compliance
- `legal-compliance-expert` - Privacy, terms, contracts
- `security-specialist` - Application security, penetration testing

### Coordination
- `orchestration-agent` - Coordinates all other agents

## 🔧 Installation

### Prerequisites
- Claude Code (Claude Desktop) installed on macOS
- Access to Claude Code's agent system

### Quick Install (macOS)

1. Clone this repository:
```bash
git clone https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator.git
cd Claude-Code-Agent-Orchestrator
```

2. Run the installation script:
```bash
./install.sh
```

Or manually:
```bash
# Copy agents to Claude configuration
cp -r agents/* ~/.claude/agents/

# Create agent workspaces directory
mkdir -p ~/.claude/agent-workspaces
```

3. Restart Claude Code to load the new agents

**Windows users**: See [windows/README.md](windows/README.md) for installation instructions.

## 🎯 Usage

### Basic Usage

Simply describe what you need in Claude Code:

```
"I need to build a SaaS pricing strategy"
→ pricing-optimization-expert will help

"Help me optimize my database queries"
→ database-architect will assist

"I want to build and launch a new product"
→ orchestration-agent coordinates multiple specialists
```

### Advanced Orchestration

For complex projects, the orchestration agent automatically:
- Decomposes tasks into specialist domains
- Runs parallel workstreams
- Manages dependencies
- Tracks progress across all agents

Example:
```
You: "I want to build a project management SaaS for remote teams"

Orchestration Plan:
├── Parallel Research Phase
│   ├── business-analyst: Market analysis
│   ├── competitive-intelligence-expert: Competitor research
│   └── product-strategy-expert: Value proposition
├── Design Phase
│   └── uiux-expert: Wireframes and user flows
├── Parallel Development
│   ├── backend-expert: API development
│   ├── frontend-expert: Dashboard UI
│   └── database-architect: Schema design
└── Launch Phase
    ├── marketing-expert: Go-to-market strategy
    └── pricing-optimization-expert: Pricing tiers
```

## 📊 How It Works

### Agent Communication

Each agent follows a standardized output format:
```json
{
  "agent": "agent-name",
  "taskId": "unique-task-id",
  "status": "completed",
  "outputs": {
    "deliverables": ["api-spec.yaml", "database-schema.sql"],
    "insights": ["Key findings and recommendations"],
    "metrics": {"performance": "values"}
  },
  "suggestedAgents": ["next-expert-to-engage"],
  "nextSteps": ["recommended-actions"]
}
```

### Work Tracking

Agents maintain their progress in `~/.claude/agent-workspaces/Agent-{Name}.md`:
- Current tasks with progress
- Completed deliverables
- Collaboration logs
- Performance metrics

### Multi-Agent Evaluation

When uncertain, the orchestrator runs parallel evaluations:
```python
# Multiple agents tackle the same problem
# System learns which performs best for specific task types
# Automatically suggests new specialist agents when gaps identified
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Adding New Agents

1. Create agent definition in `agents/your-agent-name.md`
2. Update `agent-registry.json`
3. Follow the existing agent format
4. Submit a pull request

## 📈 Performance & Learning

The system continuously improves through:
- Performance tracking per task type
- Success rate monitoring
- Execution time optimization
- Pattern recognition for agent selection

## 🔮 Future: MCP Integration

### Model Context Protocol (MCP) Support - Coming Soon!

We're excited to announce that future versions will integrate Model Context Protocol servers for enhanced capabilities:

#### Planned MCP Integrations:

**Development Tools**
- **Filesystem MCP**: Direct file system operations for agents
- **Git MCP**: Version control operations without shell commands
- **GitHub MCP**: Direct GitHub API access for PRs, issues, and repos
- **GitLab MCP**: GitLab integration for enterprise teams

**Data & Analytics**
- **PostgreSQL MCP**: Direct database queries and schema management
- **SQLite MCP**: Local database operations
- **Google Drive MCP**: Document and spreadsheet access
- **Slack MCP**: Team communication and notifications

**Cloud & Infrastructure**
- **AWS MCP**: Direct AWS service management
- **Kubernetes MCP**: K8s cluster operations
- **Terraform MCP**: Infrastructure as code management

**Specialized Tools**
- **Puppeteer MCP**: Web scraping and browser automation
- **Memory MCP**: Persistent memory across sessions
- **Brave Search MCP**: Web search capabilities
- **Fetch MCP**: Enhanced HTTP operations

### How MCP Will Enhance Agents:

1. **Direct Tool Access**: Agents won't need to use shell commands for common operations
2. **Better Performance**: Native protocol is faster than command execution
3. **Enhanced Safety**: MCP servers provide controlled access to resources
4. **Richer Capabilities**: Access to APIs and services not available via CLI
5. **Persistent Context**: Memory MCP will allow agents to remember across sessions

### Example Future Workflow:
```yaml
backend-expert:
  mcps:
    - filesystem    # Direct file operations
    - postgresql    # Database management
    - git          # Version control
    - github       # PR creation

devops-expert:
  mcps:
    - kubernetes   # Cluster management
    - aws          # Cloud resources
    - terraform    # Infrastructure
```

### Contributing to MCP Integration:
We welcome contributions for MCP integration! See our [MCP Integration Guide](docs/MCP-INTEGRATION-GUIDE.md) for details on adding MCP support to agents.

## 🐛 Troubleshooting

### Agents Not Appearing
- Ensure files are in `~/.claude/agents/`
- Restart Claude Code
- Check file permissions: `ls -la ~/.claude/agents/`

### Orchestration Issues
- Verify `agent-registry.json` is properly formatted
- Check orchestration agent logs
- Ensure all dependent agents are installed

### macOS Specific
- Grant terminal full disk access if needed
- Check Claude Code permissions in System Settings > Privacy & Security

## 📚 Documentation

- [Quick Start Guide](docs/AGENT-QUICK-START.md)
- [Complete Guide](docs/AGENT-COMPLETE-GUIDE.md)
- [Agent Work Tracking](docs/agent-work-tracker.md)
- [Blog Post: Building an AI Agent Orchestra](docs/blog-post-agent-system.md)

## 🙏 Acknowledgments

- Built with ❤️ by [W4M.ai](https://w4m.ai)
- Powered by [Claude Code](https://claude.ai/code) from [Anthropic](https://anthropic.com)
- Inspired by the amazing AI agent community

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🔗 Links

- [W4M.ai](https://w4m.ai)
- [Claude Code](https://claude.ai/code)
- [Blog Post](https://linkedin.com/in/your-profile)
- [Issues](https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator/issues)

---

**Ready to orchestrate your AI development team?** Star ⭐ this repo and start building!
