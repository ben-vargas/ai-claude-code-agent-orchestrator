import { Server } from 'socket.io';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { config } from '../config';
import { logger } from '../index';
import { getDb } from '../database/db';
import { emitAgentStatus } from '../websocket';

interface AgentInfo {
  name: string;
  category: string;
  status: 'idle' | 'running' | 'error' | 'offline';
  lastSeen: string;
  currentExecution?: string;
  metrics: {
    totalExecutions: number;
    successRate: number;
    avgExecutionTime: number;
  };
}

export function startAgentMonitor(io: Server): void {
  logger.info('Starting agent monitor');

  // Load agent registry
  const agentRegistry = loadAgentRegistry();
  
  // Monitor agent status periodically
  setInterval(() => {
    checkAllAgents(io, agentRegistry);
  }, config.monitoring.agentStatusInterval);

  // Initial check
  checkAllAgents(io, agentRegistry);
}

function loadAgentRegistry(): any {
  try {
    const registryPath = join(config.paths.agentDefinitions, 'agent-registry.json');
    if (existsSync(registryPath)) {
      const content = readFileSync(registryPath, 'utf8');
      return JSON.parse(content);
    }
  } catch (error) {
    logger.error('Failed to load agent registry:', error);
  }
  return { agents: {} };
}

function checkAllAgents(io: Server, registry: any): void {
  const db = getDb();
  
  Object.entries(registry.agents).forEach(([agentName, agentDef]: [string, any]) => {
    try {
      const agentInfo = getAgentInfo(db, agentName, agentDef);
      emitAgentStatus(io, agentName, agentInfo);
    } catch (error) {
      logger.error(`Failed to check agent ${agentName}:`, error);
    }
  });
}

function getAgentInfo(db: any, agentName: string, agentDef: any): AgentInfo {
  // Check for running executions
  const runningExecution = db.prepare(`
    SELECT id, started_at
    FROM agent_executions
    WHERE agent_name = ? AND status = 'running'
    ORDER BY started_at DESC
    LIMIT 1
  `).get(agentName) as { id: string; started_at: string } | undefined;

  // Get metrics
  const metrics = db.prepare(`
    SELECT 
      COUNT(*) as total,
      COUNT(CASE WHEN status = 'completed' THEN 1 END) as success,
      AVG(CASE 
        WHEN completed_at IS NOT NULL 
        THEN (julianday(completed_at) - julianday(started_at)) * 24 * 60 * 60
        ELSE NULL 
      END) as avg_time
    FROM agent_executions
    WHERE agent_name = ?
  `).get(agentName) as { total: number; success: number; avg_time: number | null };

  // Check workspace file for recent activity
  const workspacePath = join(config.paths.agentWorkspaces, `Agent-${agentName.replace(/-/g, '')}.md`);
  let lastSeen = new Date().toISOString();
  let status: AgentInfo['status'] = 'idle';

  if (existsSync(workspacePath)) {
    const stats = require('fs').statSync(workspacePath);
    lastSeen = stats.mtime.toISOString();
    
    // If modified recently and has running execution, mark as running
    if (runningExecution && (Date.now() - stats.mtime.getTime() < 60000)) {
      status = 'running';
    }
  } else if (!runningExecution) {
    status = 'offline';
  }

  // Determine category
  let category = 'other';
  for (const [cat, agents] of Object.entries(config.agentCategories)) {
    if ((agents as string[]).includes(agentName)) {
      category = cat;
      break;
    }
  }

  return {
    name: agentName,
    category,
    status,
    lastSeen,
    currentExecution: runningExecution?.id,
    metrics: {
      totalExecutions: metrics.total,
      successRate: metrics.total > 0 ? (metrics.success / metrics.total) * 100 : 0,
      avgExecutionTime: metrics.avg_time || 0
    }
  };
}

export function getAgentStatus(agentName: string): AgentInfo | null {
  try {
    const db = getDb();
    const registry = loadAgentRegistry();
    const agentDef = registry.agents[agentName];
    
    if (!agentDef) {
      return null;
    }

    return getAgentInfo(db, agentName, agentDef);
  } catch (error) {
    logger.error(`Failed to get agent status for ${agentName}:`, error);
    return null;
  }
}

export function getAllAgentStatuses(): AgentInfo[] {
  try {
    const db = getDb();
    const registry = loadAgentRegistry();
    const statuses: AgentInfo[] = [];

    Object.entries(registry.agents).forEach(([agentName, agentDef]: [string, any]) => {
      try {
        statuses.push(getAgentInfo(db, agentName, agentDef));
      } catch (error) {
        logger.error(`Failed to get status for agent ${agentName}:`, error);
      }
    });

    return statuses;
  } catch (error) {
    logger.error('Failed to get all agent statuses:', error);
    return [];
  }
}