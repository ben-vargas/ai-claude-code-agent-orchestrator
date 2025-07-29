# Contributing to Claude Code Agent Orchestrator

First off, thank you for considering contributing to the Claude Code Agent Orchestrator! 🎉

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- Clear description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Claude Code version
- OS and version
- Any relevant logs

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- Clear use case
- Why this enhancement would be useful
- Possible implementation approach
- Examples of how it would work

### 🤖 Adding New Agents

To add a new specialized agent:

1. **Create the agent file**: `agents/your-agent-name.md`
2. **Follow the template**:
   ```markdown
   ---
   name: your-agent-name
   description: Use this agent when...
   color: choose-a-color
   ---
   
   You are an expert...
   ```

3. **Update the registry**: Add your agent to `agents/agent-registry.json`
4. **Document expertise areas**: Be specific about capabilities
5. **Define collaboration patterns**: Which agents work well together?
6. **Add examples**: Show real-world usage scenarios

### 🔧 Improving Existing Agents

- Enhance agent prompts for better performance
- Add missing expertise areas
- Improve collaboration patterns
- Fix any incorrect information
- Add better examples

### 📚 Documentation

Help us improve documentation:

- Fix typos or clarify confusing sections
- Add more examples
- Create tutorials
- Translate documentation

## Development Process

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly**: Ensure agents work in Claude Code
5. **Commit your changes**: Use clear, descriptive commit messages
6. **Push to your fork**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

## Pull Request Guidelines

- Fill in the PR template
- Link any related issues
- Ensure all agents follow the standard format
- Update documentation if needed
- Add your agent to the README if creating a new one

## Agent Standards

### Naming Convention
- Use lowercase with hyphens: `domain-expert`
- Be specific: `database-architect` not `db-expert`
- Avoid abbreviations unless widely known

### Agent Structure
```markdown
---
name: agent-name
description: Clear description with examples
color: pick-unique-color
---

You are an expert [role] with [expertise].

Your core competencies include:
- Competency 1
- Competency 2

[Detailed sections...]

## Cross-Agent Collaboration
[Define how this agent works with others]
```

### Quality Checklist
- [ ] Clear, specific expertise definition
- [ ] Practical examples included
- [ ] Collaboration patterns defined
- [ ] No overlap with existing agents
- [ ] Follows consistent format
- [ ] Includes best practices
- [ ] Has error handling guidance

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards others
- Respect differing viewpoints

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information
- Other conduct deemed inappropriate

## Recognition

Contributors will be recognized in:
- The README contributors section
- Release notes
- Special mentions for significant contributions

## Questions?

Feel free to:
- Open an issue for clarification
- Join discussions in existing issues
- Reach out to maintainers

Thank you for helping make Claude Code Agent Orchestrator better! 🚀