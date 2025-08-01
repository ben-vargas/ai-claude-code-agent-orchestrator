# Agent Coordination System Examples

## Scenario 1: Missing MCP Server

### Situation
The database-architect agent needs PostgreSQL access but the MCP server isn't installed.

```javascript
// database-architect discovers missing capability
const tools = await executeSlashCommand('database-architect', '/alltools');
const hasPostgres = tools.mcpServers.find(s => s.server_name === 'postgresql');

if (!hasPostgres) {
  // Record the missing capability
  const capabilityId = await recordMissingCapability(
    'mcp',
    'postgresql', 
    'database-architect',
    {
      task: 'Design multi-tenant database schema',
      reason: 'Need direct database access for testing',
      impact: 'blocking'
    }
  );
  
  // System automatically proposes solution
  // In coordination-system:
  const proposal = {
    type: 'install_mcp',
    details: {
      serverName: 'postgresql',
      steps: [
        {
          action: 'clone',
          command: 'git clone https://github.com/modelcontextprotocol/postgres-mcp'
        },
        {
          action: 'setup',
          command: 'cd postgres-mcp && npm install'
        },
        {
          action: 'configure',
          config: {
            command: 'node',
            args: ['./postgres-mcp/index.js'],
            env: { DATABASE_URL: 'postgresql://localhost/dev' }
          }
        }
      ]
    },
    confidence: 0.9,
    safety: 0.85
  };
  
  // Check if auto-approval is possible
  if (proposal.confidence >= 0.85 && proposal.safety >= 0.8) {
    // Request approval (or auto-approve if configured)
    const approval = await requestApproval('install_mcp', proposal);
    
    if (approval.status === 'approved') {
      const result = await installMCPServer(proposal, 'database-architect');
      // PostgreSQL MCP is now available!
    }
  }
}
```

### Result
- Missing capability recorded and tracked
- Solution automatically proposed
- Installation completed (with approval)
- Agent can continue work

## Scenario 2: Agent Delegation

### Situation
Backend-expert completes API design and needs frontend components built.

```javascript
// backend-expert delegates to frontend-expert
const delegationResult = await delegateTask(
  'backend-expert',
  'frontend-expert',
  {
    title: 'Create React components for User API',
    description: 'Build frontend components for the user management endpoints',
    priority: 'high',
    deliverables: [
      'UserList.jsx',
      'UserDetail.jsx', 
      'UserForm.jsx'
    ],
    context: {
      apiSpec: '/api/v1/users endpoints',
      endpoints: [
        'GET /users',
        'GET /users/:id',
        'POST /users',
        'PUT /users/:id'
      ],
      authRequired: true
    },
    dependencies: ['api-spec.yaml', 'auth-context.js']
  }
);

// In SQLite, this creates:
// - Entry in agent_coordination_queue
// - Notification for frontend-expert
// - Task tracking record

// frontend-expert receives notification and claims task
const task = await claimCoordinationTask('frontend-expert', delegationResult.coordinationId);

// Work proceeds with progress tracking
await updateCoordinationProgress(task.coordinationId, {
  status: 'in_progress',
  progress: 'Created UserList component with pagination'
});

// Complete with deliverables
await completeCoordinationTask(task.coordinationId, {
  status: 'completed',
  deliverables: [
    'components/UserList.jsx',
    'components/UserDetail.jsx',
    'components/UserForm.jsx',
    'hooks/useUserAPI.js' // Bonus deliverable!
  ],
  insights: ['Added custom hook for API reusability']
});
```

### Result
- Seamless handoff between agents
- Progress tracked in SQLite
- Both agents maintain context
- Collaboration history preserved

## Scenario 3: Expertise Not Available

### Situation
Mobile-expert needs blockchain expertise for crypto wallet feature.

```javascript
// mobile-expert requests collaboration
const collabRequest = await requestCollaboration(
  'mobile-expert',
  ['blockchain', 'cryptography', 'wallet'],
  {
    task: 'Implement secure crypto wallet in React Native',
    requirements: [
      'Generate and store private keys securely',
      'Sign transactions offline',
      'Support multiple cryptocurrencies',
      'Biometric authentication'
    ],
    timeline: 'high_priority'
  }
);

// System checks available agents
// Result: blockchain-expert exists and is suitable

// blockchain-expert receives notification
const collaboration = await acceptCollaboration(
  'blockchain-expert',
  collabRequest.collaborationId
);

// Agents work together
await addCollaborationUpdate(collabRequest.collaborationId, {
  agent: 'blockchain-expert',
  update: 'Provided Web3 integration pattern and key management strategy',
  deliverables: ['WalletService.js', 'KeyManagement.md']
});

await addCollaborationUpdate(collabRequest.collaborationId, {
  agent: 'mobile-expert',
  update: 'Implemented UI and integrated with secure storage',
  deliverables: ['WalletScreen.jsx', 'BiometricAuth.js']
});
```

### Result
- Expertise gap identified and filled
- Agents collaborate effectively
- Knowledge shared and preserved
- Both agents learn from interaction

## Scenario 4: Creating New Agent

### Situation
Multiple agents repeatedly need GraphQL expertise, but no GraphQL expert exists.

```javascript
// System detects pattern in missing_capabilities
const graphqlRequests = await db.all(`
  SELECT COUNT(*) as count, COUNT(DISTINCT requested_by_agent) as unique_agents
  FROM missing_capabilities
  WHERE capability_type = 'expertise' 
    AND capability_name LIKE '%graphql%'
`);
// Result: 15 requests from 5 different agents

// orchestration-agent proposes new agent
const agentProposal = await proposeNewAgent('orchestration-agent', {
  name: 'graphql-expert',
  description: 'Expert in GraphQL API design, implementation, and optimization',
  expertise: ['GraphQL', 'Apollo', 'Schema Design', 'Resolvers', 'Performance'],
  basedOn: 'backend-expert', // Use as template
  justification: '15 requests for GraphQL help from 5 agents in past week',
  expectedUsage: {
    frequency: 'daily',
    requestingAgents: ['backend-expert', 'frontend-expert', 'api-designer'],
    taskTypes: ['schema design', 'resolver implementation', 'query optimization']
  }
});

// If approved (auto or manual based on config)
if (agentProposal.status === 'approved') {
  // Generate agent definition
  const agentDef = await generateAgentDefinition({
    ...agentProposal,
    includeTools: ['GraphQL playground', 'Apollo devtools'],
    mcpRequirements: ['graphql-server'],
    collaborationPatterns: {
      worksWellWith: ['backend-expert', 'frontend-expert'],
      expertise: 'GraphQL and API optimization'
    }
  });
  
  // Create agent files
  await createAgent('graphql-expert', agentDef);
  
  // Update registry
  await updateAgentRegistry('graphql-expert', agentDef);
}
```

### Result
- Pattern detected from repeated requests
- New agent proposed with justification
- Agent created to fill expertise gap
- System self-improves based on needs

## Scenario 5: Parallel Coordination

### Situation
Building e-commerce platform requires parallel work from multiple agents.

```javascript
// orchestration-agent creates parallel work plan
const parallelTasks = [
  {
    agent: 'backend-expert',
    task: 'Build product catalog API',
    dependencies: []
  },
  {
    agent: 'frontend-expert', 
    task: 'Create product browsing UI',
    dependencies: []
  },
  {
    agent: 'database-architect',
    task: 'Design inventory schema',
    dependencies: []
  },
  {
    agent: 'devops-sre-expert',
    task: 'Set up CI/CD pipeline',
    dependencies: []
  }
];

// Create all tasks simultaneously
const coordinationIds = await Promise.all(
  parallelTasks.map(t => 
    delegateTask('orchestration-agent', t.agent, {
      ...t.task,
      parallel: true,
      sharedContext: 'e-commerce-platform'
    })
  )
);

// Agents work in parallel, sharing discoveries
// database-architect discovers useful pattern
await recordDiscovery('database-architect', {
  type: 'pattern',
  name: 'Optimistic inventory locking',
  details: 'Use Redis for temporary inventory holds during checkout',
  effectiveness: 0.9,
  shareWith: ['backend-expert']
});

// backend-expert uses the discovery
const discovery = await getSharedDiscoveries('backend-expert');
// Implements Redis-based inventory management
```

### Result
- True parallel execution
- Agents share discoveries in real-time
- Work completes 4x faster
- Knowledge preserved for future

## Coordination Benefits Summary

1. **Autonomous Problem Solving**
   - Agents identify and resolve capability gaps
   - System proposes solutions automatically
   - Reduced human intervention needed

2. **Efficient Collaboration**
   - Direct agent-to-agent communication
   - Task handoffs without friction
   - Expertise sharing across team

3. **Self-Improving System**
   - Tracks patterns in missing capabilities
   - Creates new agents as needed
   - Installs tools when required

4. **Parallel Execution**
   - Multiple agents work simultaneously
   - Resource allocation managed
   - Discoveries shared in real-time

5. **Safety and Control**
   - All actions logged and auditable
   - Configurable approval thresholds
   - Rollback capabilities
   - Human oversight when needed