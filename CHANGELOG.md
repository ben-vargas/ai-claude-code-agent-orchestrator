# Changelog

All notable changes to the Claude Code Agent Orchestrator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5] - 2024-01-31

### Added
- MCP Server Manager script (`scripts/mcp-server-manager.sh`)
- Automatic MCP server detection and validation
- Copy MCP servers from Claude Desktop to Claude Code
- MCP requirements file (`agents/mcp-requirements.json`)
- Agent-specific MCP requirement checking
- Critical server warnings with graceful degradation
- MCP server validation in installation process
- MCP checks in all orchestration scripts

### Enhanced
- Installation script now handles MCP server configuration
- Orchestration scripts check MCP servers before execution
- Agent worker validates agent-specific MCP requirements
- Documentation updated with MCP server setup instructions

### Development Notes
- Developed in 30 minutes with Claude Code
- Ensures agents have required tools before execution
- Provides both automatic and interactive management options

## [0.4] - 2024-01-30

### Added
- Auto-proceed timeouts for interactive mode
- Configurable timeout durations based on decision criticality
- Dynamic timeout calculation using project level and timeline
- Visual countdown with progress bars
- Warning messages at 60, 30, and 15 seconds
- Timeout configuration file (`orchestration-timeout-config.json`)
- Comprehensive timeout documentation

### Enhanced
- Orchestration agent v2 with timeout handling
- Interactive mode now continues automatically after timeout
- Progress tracking includes timeout events

### Development Notes
- Developed in 45 minutes with Claude Code

## [0.3] - 2024-01-30

### Added
- Project Levels system (1-5) from MVP to Enterprise
- Interactive mode for orchestration with user guidance
- Progress tracking with real-time status updates
- Visual progress indicators and ASCII progress bars
- Orchestration plan file (`orchestration-plan.md`)
- Timeline logging in JSONL format for debugging
- Enhanced orchestration agent v2

### Enhanced
- Agent selection based on project level
- Decision points with context and recommendations
- Comprehensive progress monitoring

### Development Notes
- Developed in 40 minutes with Claude Code

## [0.2] - 2024-01-30

### Added
- SQLite memory system for persistent agent memory
- Automatic fallback to filesystem when SQLite unavailable
- Memory adapter agent for unified memory interface
- MCP server for SQLite memory operations
- Cross-agent memory sharing capabilities
- Memory migration tools from filesystem to SQLite
- Rich querying with importance-based retrieval

### Enhanced
- Installation script with SQLite memory setup option
- Memory usage examples for all agent types

### Development Notes
- Developed in 30 minutes with Claude Code

## [0.1] - 2024-01-20

### Added
- Initial release with 24 specialized AI agents
- Agent orchestration system
- Standardized agent communication protocol
- Agent registry with expertise mapping
- Installation script for macOS
- Comprehensive documentation
- Work tracking in agent workspaces

### Features
- Backend, Frontend, Mobile, AI/ML expert agents
- Strategy agents (Business, Product, Pricing, Competitive)
- Infrastructure agents (Cloud, DevOps, Database)
- Design and Growth agents
- Security and Compliance agents
- Quality and Testing agents

### Notes
- Created in less than 1 hour using Claude Code
- Built for seamless integration with Claude Desktop
- MCP-ready architecture for future enhancements