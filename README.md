# Claude Code Agent Orchestrator 🎭

[![Version](https://img.shields.io/badge/version-0.5-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Built with](https://img.shields.io/badge/built%20with-Claude%20Code-purple.svg)](https://claude.ai/code)

A comprehensive system of 24 specialized AI agents that work together to handle complex software development tasks. Built for [Claude Code](https://claude.ai/code) by [W4M.ai](https://w4m.ai).

## 🎉 What's New in v0.5

**MCP Server Management**: Automatic detection, validation, and configuration of Model Context Protocol servers. Ensures agents have access to required tools before execution.

- 🔌 Auto-detect MCP servers from Claude Desktop
- ✅ Validate server executables and dependencies
- 📋 Copy servers between Desktop and Code configs
- ⚠️ Critical server warnings with graceful degradation
- 🤖 Agent-specific MCP requirement checking

[See full changelog](CHANGELOG.md)

## 📊 Version Timeline

| Version | Release Date | Key Features | Development Time |
|---------|--------------|--------------|------------------|
| **v0.1** | Jan 2024 | Initial release - 24 specialized agents | < 1 hour with Claude Code |
| **v0.2** | Jan 2024 | SQLite memory with filesystem fallback | 30 minutes |
| **v0.3** | Jan 2024 | Project levels (1-5) & interactive mode | 40 minutes |
| **v0.4** | Jan 2024 | Auto-proceed timeouts for interactive mode | 45 minutes |
| **v0.5** | Jan 2024 | MCP server management & validation | 30 minutes |
| **v0.6** | *Upcoming* | True parallel execution with multi-terminal orchestration | *In Development* |

## 🚀 Overview

Transform your development workflow with specialized AI agents that collaborate like a world-class team. Each agent is an expert in their domain, from backend architecture to pricing strategy, working together under intelligent orchestration.

### Key Features

- **24 Specialized Agents**: Expert knowledge across all development domains
- **Intelligent Orchestration**: Automatic task routing and parallel execution
- **SQLite Memory System** (v0.2): Persistent memory with automatic filesystem fallback
- **Project Levels** (v0.3): Configurable quality levels from MVP (1) to Enterprise (5)
- **Interactive Mode** (v0.3): Guide decisions with clarifying questions
- **Auto-Proceed Timeouts** (v0.4): Continue automatically if no response received
- **MCP Server Management** (v0.5): Automatic detection and validation of required tools
- **Multi-Agent Evaluation**: Compare approaches from multiple experts
- **Self-Improving System**: Learns optimal agent selection over time
- **Progress Tracking**: Real-time monitoring of orchestration status
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

The installation script will:
- Copy all agents to your Claude configuration
- Set up SQLite memory support (optional)
- Check and configure MCP servers automatically
- Verify the installation

Or manually:
```bash
# Copy agents to Claude configuration
cp -r agents/* ~/.claude/agents/

# Create agent workspaces directory
mkdir -p ~/.claude/agent-workspaces

# Check MCP servers
./scripts/mcp-server-manager.sh --auto
```

3. Restart Claude Code to load the new agents

**Windows users**: See [windows/README.md](windows/README.md) for installation instructions.

### MCP Server Configuration

The orchestrator now automatically checks for required MCP servers:

```bash
# Check and configure MCP servers
./scripts/mcp-server-manager.sh

# Options:
# 1. List all MCP servers
# 2. Compare Desktop vs Code configs
# 3. Copy servers from Desktop to Code
# 4. Validate all MCP servers
# 5. Check required MCP servers
# 6. Full setup (recommended)
```

Critical MCP servers for full functionality:
- **filesystem**: File operations
- **memory**: Persistent agent memory  
- **web**: Web browsing and search
- **git**: Version control

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

## 🚀 Living Dangerously? Advanced Rules (Use at Your Own Risk!)

Hey there, brave soul! 👋 

So you want your agents to have more freedom? We get it. Sometimes you need to let the agents off the leash in a controlled environment. That's why we've created some "dangerous rules" that give agents extensive permissions.

### 🎭 The "Hold My Coffee" Rules

In the `dangerous-rules/` directory, you'll find configuration files that are basically the equivalent of giving your agents the keys to the kingdom. These include:

- **🔥 Permissive Dev Rules**: "Yes, agent, you can delete files without asking"
- **🤖 Automation Rules**: "Go ahead, deploy to production at 3 AM"
- **🔬 Research Rules**: "Analyze ALL the data, I trust you"
- **🎪 Orchestration Rules**: "You're the boss of all the other agents now"

### ⚠️ The Fine Print (Please Actually Read This)

Look, we need to be crystal clear here: **These rules are DANGEROUS**. Like, "accidentally delete your entire project" dangerous. By using them, you're basically saying:

1. **"I understand what I'm doing"** (Do you though? Really? 🤔)
2. **"I accept full responsibility"** (No takebacks!)
3. **"I won't blame anyone else"** (That includes us, Claude, or your cat)
4. **"I'm using a disposable environment"** (Right? RIGHT?!)

### 🛡️ How to Use Them (Somewhat) Safely

```bash
# Step 1: Read the warnings
cat dangerous-rules/README.md
cat dangerous-rules/DISCLAIMER.md

# Step 2: Set up an isolated environment
./dangerous-rules/setup-isolated-env.sh

# Step 3: Question your life choices

# Step 4: If you're still sure...
# Use them in a VM or container that you can nuke from orbit
```

### 🎯 Good Use Cases
- **Testing in VMs**: Where `rm -rf` is just a Tuesday
- **CI/CD pipelines**: In containers that live for 5 minutes
- **Research sandboxes**: Where data has no feelings
- **That old laptop**: You were going to reformat anyway

### 🚫 Terrible Use Cases
- Your work computer (unless you hate your job)
- Production servers (unless you hate your company)
- Your mom's computer (unless you hate family dinners)
- Any system with data you care about

### 🎓 Prerequisites

Before even THINKING about using these rules, you should:
- Understand how Claude Code rules work
- Know what each permission actually does
- Have reliable backups (test them!)
- Possess a healthy fear of `rm -rf`
- Maybe have a drink ready for afterwards

### ⚖️ Legal Stuff (But Fun!)

By using these dangerous rules, you acknowledge that:
- You're an adult (or a very reckless teenager)
- You understand the risks (destruction, chaos, tears)
- You take full responsibility for your actions
- You won't hold us responsible for sharing knowledge
- You might lose data (probably will, actually)
- This is YOUR adventure (we're just sharing our tools)

**Important**: If you don't agree with taking full responsibility, then don't use these dangerous rules. In fact, you don't have permission to use them. Simple as that! 🚫

**TL;DR**: We're just sharing what we use in our isolated test environments. If your computer catches fire, your data disappears, or your agents achieve sentience and take over, that's on you, friend! You chose to use these tools. 🔥💾🤖

### 🏃‍♂️ Quick Escape Route

Things going wrong? Here's your panic button:

```bash
# EMERGENCY STOP
./dangerous-rules/emergency-cleanup.sh
# or just
pkill -f claude
```

Remember: With great power comes great opportunity to mess things up. Use wisely! Or don't. We're not your supervisor. 😄

---

**Seriously though**: These rules exist for legitimate testing and research purposes in isolated environments. Please be responsible. Your future self will thank you.

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

## 🚀 Roadmap & Next Steps

### v0.6 (In Development) - True Parallel Execution
- 🖥️ **Multi-Terminal Orchestration**: Spawn multiple Claude instances for true parallelism
- ⚡ **3x Speed Improvement**: Run independent agents simultaneously
- 📊 **Resource Management**: Smart allocation across terminals
- 🔄 **Advanced Coordination**: Inter-terminal communication protocol
- 📈 **Live Progress Dashboard**: Real-time visualization of parallel execution

[See detailed design](docs/PARALLEL-EXECUTION-DESIGN.md)

### Future Versions
- **v0.7**: Extended MCP Integration Suite (GitHub, Slack, AWS, etc.)
- **v0.8**: Agent Learning System with Performance Analytics
- **v0.9**: Visual Workflow Designer
- **v1.0**: Enterprise Features (SSO, Audit Logs, SLA)
- **v1.1**: Production-Ready Platform

### Contributing Ideas
- Custom agent creation wizard
- Agent marketplace for community contributions
- Integration with popular development tools
- Cross-platform support (Windows, Linux)
- Cloud-hosted orchestration service

## 🔗 Links

- [W4M.ai](https://w4m.ai)
- [Claude Code](https://claude.ai/code)
- [Blog Post](https://linkedin.com/in/your-profile)
- [Issues](https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator/issues)

---

**Ready to orchestrate your AI development team?** Star ⭐ this repo and start building!
