# Agent Quick Start Guide

Welcome to the Claude Agent System! This guide will get you up and running with our specialized AI agents in minutes.

## 🚀 Quick Start

### 1. Understanding Agents

Agents are specialized AI experts that handle specific domains:
- **Engineering**: backend, frontend, mobile, AI/ML, blockchain
- **Strategy**: product, business analysis, pricing, competitive intelligence  
- **Infrastructure**: cloud architecture, DevOps, database, performance
- **Design**: UI/UX
- **Growth**: marketing, social media, customer success
- **Operations**: business operations, legal compliance
- **Security**: application security, cloud security
- **Coordination**: orchestration agent (manages other agents)

### 2. Basic Usage

Simply describe what you need, and the appropriate agent will be selected:

```
"I need to design a pricing strategy for my SaaS"
→ pricing-optimization-expert will help

"Help me optimize my database queries"
→ database-architect will assist

"I want to build a mobile app"
→ mobile-expert will guide you
```

### 3. Complex Projects

For multi-faceted projects, the orchestration agent coordinates multiple specialists:

```
"I want to build and launch a new product"
→ orchestration-agent coordinates:
   - business-analyst (market research)
   - product-strategy-expert (product definition)
   - uiux-expert (design)
   - backend/frontend experts (development)
   - qa-test-engineer (testing)
   - marketing-expert (launch)
```

## 📋 Common Scenarios

### Starting a New Project
1. **Idea Validation**: business-analyst + product-strategy-expert
2. **Technical Planning**: cloud-architect + database-architect
3. **Development**: backend/frontend/mobile experts
4. **Launch**: marketing + customer-success experts

### Improving Existing Product
1. **Performance Issues**: performance-engineer
2. **Security Concerns**: security-specialist
3. **User Experience**: uiux-expert + frontend-expert
4. **Growth**: marketing-expert + pricing-optimization-expert

### Technical Challenges
- **API Design**: backend-expert
- **Database Optimization**: database-architect
- **Cloud Migration**: cloud-architect + devops-sre-expert
- **ML Integration**: ai-ml-expert

## 🎯 Agent Specialties

### Engineering Agents
- **backend-expert**: APIs, microservices, server-side logic
- **frontend-expert**: React, Vue, Angular, UI development
- **mobile-expert**: iOS, Android, React Native, Flutter
- **ai-ml-expert**: Machine learning, AI, NLP, computer vision
- **blockchain-expert**: Smart contracts, Web3, DeFi

### Strategic Agents
- **product-strategy-expert**: Product-market fit, roadmaps
- **business-analyst**: Market research, competitive analysis
- **pricing-optimization-expert**: Pricing strategies, A/B testing
- **competitive-intelligence-expert**: Competitor tracking

### Infrastructure Agents
- **cloud-architect**: AWS, Azure, cloud design
- **devops-sre-expert**: CI/CD, monitoring, deployment
- **database-architect**: Database design, optimization
- **performance-engineer**: Speed optimization, load testing

### Customer-Facing Agents
- **uiux-expert**: User research, design, prototyping
- **marketing-expert**: Growth strategies, campaigns
- **customer-success-expert**: Onboarding, retention
- **social-media-expert**: Social strategy, community

## 💡 Pro Tips

### 1. Be Specific
More detail = better results:
- ❌ "Help with database"
- ✅ "Optimize PostgreSQL queries for a table with 10M rows"

### 2. Mention Constraints
Include your limitations:
- Budget constraints
- Timeline requirements
- Technical constraints
- Team size

### 3. Ask for Collaboration
Request multiple agents when needed:
- "I need both technical architecture and cost analysis"
- "Help with both frontend design and backend API"

### 4. Iterate
Agents can refine their work:
- Start with high-level planning
- Dive into specific implementation
- Request reviews and improvements

## 🔄 Agent Collaboration

Agents work together seamlessly:

```
user: "I need a secure payment system"

Collaboration:
1. business-operations-expert: Payment provider selection
2. backend-expert: API integration
3. security-specialist: Security implementation
4. frontend-expert: UI components
5. qa-test-engineer: Testing strategy
```

## 📊 Progress Tracking

Each agent maintains work logs:
- Current tasks and progress
- Completed deliverables
- Collaboration with other agents
- Suggested next steps

Access agent work via: `.claude/agent-workspaces/Agent-{Name}.md`

## 🆘 Getting Help

### Not Sure Which Agent?
Just describe your need - the orchestration agent will coordinate the right experts.

### Need Multiple Perspectives?
Ask for parallel evaluation:
"Compare different approaches to [your challenge]"

### Want to See Agent Thinking?
Request detailed explanations:
"Explain your reasoning for this recommendation"

## 🎬 Quick Examples

### Example 1: MVP Development
```
You: "I want to build an MVP for a task management app"
System: Engages product-strategy-expert → uiux-expert → backend-expert → frontend-expert
Result: Validated concept → Design → Working MVP
```

### Example 2: Performance Crisis
```
You: "Our app is crashing under load"
System: Engages performance-engineer + devops-sre-expert
Result: Identified bottlenecks → Optimizations → 10x improvement
```

### Example 3: Growth Challenge
```
You: "We need more users"
System: Engages marketing-expert + pricing-optimization-expert + customer-success-expert
Result: Growth strategy → Pricing adjustment → Improved retention
```

## 🚦 Ready to Start?

Simply describe what you want to achieve, and our agents will guide you from idea to implementation. The more context you provide, the better the results!

Remember: You're not just getting advice - you're getting a team of specialists working together to make your project successful.

**Start with**: "I want to..." or "Help me with..." or "How do I..."