# Memory System Usage Examples

This document shows practical examples of how agents use the memory system.

## Backend Expert Memory Usage

### Storing a Successful API Pattern

```javascript
// After implementing a successful authentication system
memory.store('backend-expert', 'auth-jwt-pattern-2024', {
  pattern: 'JWT with refresh tokens',
  implementation: {
    accessTokenExpiry: '15m',
    refreshTokenExpiry: '7d',
    storageStrategy: 'httpOnly cookies for refresh, memory for access'
  },
  securityNotes: 'Prevents XSS attacks, allows token rotation',
  projectContext: 'e-commerce-platform',
  collaboratedWith: ['security-specialist', 'frontend-expert']
}, 9, ['authentication', 'jwt', 'security', 'successful-pattern']);
```

### Retrieving Context Before Starting Task

```javascript
// User: "I need to implement user authentication"

// Backend expert first checks memories:
const authMemories = memory.search('backend-expert', 'authentication', 7);
const jwtPattern = memory.retrieve('backend-expert', 'auth-jwt-pattern-2024');

// Response informed by memory:
"I recall implementing a successful JWT authentication pattern with refresh tokens.
Based on my previous experience, I recommend:
1. Using httpOnly cookies for refresh tokens (prevents XSS)
2. 15-minute expiry for access tokens
3. Implementing token rotation for security
This approach worked well in the e-commerce platform project."
```

## Orchestration Agent Cross-Agent Memory

### Storing Multi-Agent Collaboration Outcome

```javascript
// After successful project completion
memory.store('orchestration-agent', 'saas-mvp-workflow-pattern', {
  workflow: {
    phase1: ['business-analyst', 'product-strategy-expert'],
    phase2: ['uiux-expert', 'database-architect'],
    phase3: ['backend-expert', 'frontend-expert'],
    phase4: ['qa-test-engineer', 'devops-sre-expert']
  },
  parallelizationOpportunities: [
    'UI design and database schema can run in parallel',
    'Backend and frontend development with API contract'
  ],
  lessonsLearned: {
    success: 'Early API contract definition enabled parallel work',
    improvement: 'Include security-specialist earlier in phase 2'
  },
  totalDuration: '6 weeks',
  clientSatisfaction: 'exceeded expectations'
}, 10, ['workflow', 'saas', 'mvp', 'successful-pattern', 'multi-agent']);
```

## Frontend Expert Learning from Error

### Storing Error Resolution

```javascript
// After resolving a performance issue
memory.store('frontend-expert', 'react-render-optimization-issue', {
  problem: 'Component re-rendering 100+ times causing UI freeze',
  diagnosis: 'Missing React.memo and useCallback in list items',
  solution: {
    code: 'React.memo(ListItem) + useCallback for event handlers',
    explanation: 'Prevented unnecessary re-renders of list items'
  },
  performanceImprovement: '95% reduction in render time',
  preventionTips: [
    'Always memoize list item components',
    'Use React DevTools Profiler to identify issues'
  ]
}, 8, ['react', 'performance', 'error-resolution', 'optimization']);
```

## QA Test Engineer Pattern Recognition

### Storing Testing Pattern

```javascript
// After identifying recurring test pattern
memory.store('qa-test-engineer', 'api-integration-test-pattern', {
  pattern: 'Contract testing for microservices',
  implementation: {
    tool: 'Pact',
    approach: 'Consumer-driven contracts',
    benefits: 'Catch breaking changes before deployment'
  },
  applicableScenarios: [
    'Multiple services with shared APIs',
    'Teams working independently',
    'Frequent API changes'
  ],
  metrics: {
    bugsPreventedMonthly: 15,
    deploymentFailuresReduced: '80%'
  }
}, 9, ['testing', 'api', 'microservices', 'contract-testing', 'pattern']);
```

## Memory-Driven Agent Improvements

### Business Analyst Market Research Memory

```javascript
// Storing market insights
memory.store('business-analyst', 'saas-pricing-research-2024', {
  findings: {
    competitorAnalysis: {
      'competitor-a': { starter: 29, pro: 99, enterprise: 299 },
      'competitor-b': { basic: 39, business: 149, custom: 'contact' }
    },
    marketTrends: [
      'Usage-based pricing gaining traction',
      'Free tier essential for developer tools',
      'Annual discounts standard at 20%'
    ],
    successfulModels: {
      PLG: 'Free tier → paid conversion at 3-5%',
      Enterprise: 'Direct sales with POC'
    }
  },
  recommendations: 'Hybrid model with generous free tier + enterprise sales',
  dataSource: 'Analysis of 50 SaaS companies in similar space'
}, 9, ['pricing', 'saas', 'market-research', 'competitor-analysis']);

// Later retrieval by product-strategy-expert
const pricingMemory = memory.search('business-analyst', 'saas pricing', 7);
// Uses this data to inform pricing strategy
```

## Cross-Session Continuity Example

### Session 1: Initial Implementation

```javascript
// Backend expert in session 1
memory.store('backend-expert', 'project-x-api-structure', {
  structure: {
    '/api/v1/users': 'User management',
    '/api/v1/products': 'Product catalog',
    '/api/v1/orders': 'Order processing'
  },
  decisions: {
    versioning: 'URL-based (/v1/)',
    authentication: 'Bearer token in header',
    pagination: 'Cursor-based for scalability'
  },
  todoItems: [
    'Implement rate limiting',
    'Add request validation middleware',
    'Set up monitoring'
  ]
}, 8, ['api', 'architecture', 'project-x', 'in-progress']);
```

### Session 2: Continuing Work (Days Later)

```javascript
// User: "Continue working on the API we discussed"

// Backend expert retrieves context:
const projectMemory = memory.retrieve('backend-expert', 'project-x-api-structure');
const recentSessions = sessions.getRecentSessions('backend-expert', 3);

// Response with full context:
"I remember our API structure for Project X. We have three main endpoints 
set up with URL-based versioning. My notes indicate we still need to:
1. Implement rate limiting
2. Add request validation middleware  
3. Set up monitoring

Shall I continue with the rate limiting implementation?"
```

## Memory Analytics Dashboard

### Tracking Agent Performance

```javascript
// Memory statistics aggregation
const agentStats = {
  'backend-expert': {
    totalMemories: 234,
    avgImportance: 7.2,
    topTags: ['api', 'architecture', 'optimization'],
    successPatterns: 45,
    errorResolutions: 12
  },
  'frontend-expert': {
    totalMemories: 189,
    avgImportance: 6.8,
    topTags: ['react', 'ui', 'performance'],
    successPatterns: 38,
    errorResolutions: 23
  }
};

// Identifying improvement opportunities
const crossAgentInsights = memory.search('all', 'collaboration', 8);
// "Frontend-backend API contract discussions have 90% success rate 
//  when both agents access shared memory context"
```

## Best Practices from Memory Usage

1. **Consistent Tagging**: Use standardized tags across agents for better cross-referencing
2. **Importance Scoring**: Be thoughtful about importance - not everything is a 9 or 10
3. **Context Preservation**: Include enough context to understand the memory months later
4. **Cross-Agent References**: Always note which agents were involved in collaborative work
5. **Error Documentation**: Failed approaches are as valuable as successful ones
6. **Regular Pruning**: Review and update importance scores as patterns become outdated