import { join } from 'path';
import { homedir } from 'os';

export const config = {
  port: process.env.PORT || 3001,
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:5173',
  
  database: {
    path: process.env.DB_PATH || join(__dirname, '../../data/orchestrator.db'),
    walMode: true,
    verbose: process.env.NODE_ENV === 'development'
  },
  
  paths: {
    agentWorkspaces: join(homedir(), '.claude', 'agent-workspaces'),
    agentDefinitions: join(process.cwd(), '../../agents'),
    orchestratorLogs: join(process.cwd(), '../../logs'),
    projectRoot: join(process.cwd(), '../..')
  },
  
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
    jwtExpiresIn: '24h',
    bcryptRounds: 10
  },
  
  websocket: {
    pingInterval: 30000,
    pingTimeout: 5000
  },
  
  monitoring: {
    fileWatchInterval: 1000,
    agentStatusInterval: 5000,
    metricsRetentionDays: 30
  },
  
  orchestrator: {
    maxParallelTerminals: 4,
    defaultTimeoutMinutes: 30,
    webhookEndpoint: '/api/webhooks/notify'
  },
  
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
  }
};

export const agentCategories = {
  engineering: ['backend-expert', 'frontend-expert', 'mobile-expert', 'ai-ml-expert', 'blockchain-expert', 'performance-engineer'],
  strategy: ['business-analyst', 'product-strategy-expert', 'pricing-optimization-expert', 'competitive-intelligence-expert'],
  infrastructure: ['cloud-architect', 'devops-sre-expert', 'database-architect'],
  design: ['uiux-expert'],
  growth: ['marketing-expert', 'social-media-expert', 'customer-success-expert'],
  operations: ['business-operations-expert', 'legal-compliance-expert', 'data-analytics-expert'],
  security: ['security-specialist', 'cloud-security-auditor'],
  quality: ['qa-test-engineer'],
  coordination: ['orchestration-agent']
};