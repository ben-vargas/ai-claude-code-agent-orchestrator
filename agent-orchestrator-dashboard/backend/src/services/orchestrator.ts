import { spawn, ChildProcess } from 'child_process';
import { v4 as uuidv4 } from 'uuid';
import { join } from 'path';
import { getDb } from '../database/db';
import { config } from '../config';
import { logger } from '../index';
import { io } from '../index';
import { emitExecutionUpdate, emitLogEntry } from '../websocket';

interface ExecutionOptions {
  level?: number;
  interactive?: boolean;
  timeout?: number;
  maxParallelTerminals?: number;
}

const activeExecutions = new Map<string, ChildProcess>();

export async function startProjectExecution(
  projectId: string,
  options: ExecutionOptions = {}
): Promise<any> {
  const db = getDb();
  
  // Check if project exists
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(projectId);
  if (!project) {
    throw new Error('Project not found');
  }

  // Check for existing running execution
  const runningExecution = db.prepare(`
    SELECT COUNT(*) as count
    FROM agent_executions
    WHERE project_id = ? AND status = 'running'
  `).get(projectId) as { count: number };

  if (runningExecution.count > 0) {
    throw new Error('Project already has a running execution');
  }

  // Create execution record
  const executionId = uuidv4();
  const executionPlanId = uuidv4();

  db.prepare(`
    INSERT INTO execution_plans (id, project_id, plan)
    VALUES (?, ?, ?)
  `).run(executionPlanId, projectId, JSON.stringify({
    level: options.level || 2,
    maxParallelTerminals: options.maxParallelTerminals || config.orchestrator.maxParallelTerminals
  }));

  db.prepare(`
    INSERT INTO agent_executions (id, project_id, agent_name, status)
    VALUES (?, ?, 'orchestration-agent', 'running')
  `).run(executionId, projectId);

  // Start orchestrator process
  const orchestratorPath = join(config.paths.projectRoot, 'scripts', 'orchestrator.sh');
  const projectConfig = JSON.parse(project.config || '{}');
  
  const args = [
    projectConfig.name || project.name,
    String(options.level || 2),
    options.interactive ? 'true' : 'false',
    String(options.timeout || config.orchestrator.defaultTimeoutMinutes)
  ];

  const orchestratorProcess = spawn('bash', [orchestratorPath, ...args], {
    cwd: config.paths.projectRoot,
    env: {
      ...process.env,
      WEBHOOK_URL: `http://localhost:${config.port}${config.orchestrator.webhookEndpoint}`,
      EXECUTION_ID: executionId,
      PROJECT_ID: projectId
    }
  });

  activeExecutions.set(executionId, orchestratorProcess);

  // Handle process output
  orchestratorProcess.stdout.on('data', (data) => {
    const message = data.toString();
    logger.info(`[Orchestrator ${executionId}] ${message}`);
    
    emitLogEntry(io, {
      executionId,
      agentName: 'orchestration-agent',
      level: 'info',
      message: message.trim()
    });
  });

  orchestratorProcess.stderr.on('data', (data) => {
    const message = data.toString();
    logger.error(`[Orchestrator ${executionId}] ${message}`);
    
    emitLogEntry(io, {
      executionId,
      agentName: 'orchestration-agent',
      level: 'error',
      message: message.trim()
    });
  });

  orchestratorProcess.on('close', (code) => {
    logger.info(`Orchestrator ${executionId} exited with code ${code}`);
    activeExecutions.delete(executionId);

    // Update execution status
    const status = code === 0 ? 'completed' : 'failed';
    db.prepare(`
      UPDATE agent_executions
      SET status = ?, completed_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(status, executionId);

    emitExecutionUpdate(io, executionId, {
      status,
      exitCode: code
    });
  });

  // Emit initial update
  emitExecutionUpdate(io, executionId, {
    status: 'started',
    projectId,
    startedAt: new Date().toISOString()
  });

  return {
    executionId,
    projectId,
    status: 'running',
    startedAt: new Date().toISOString()
  };
}

export async function stopProjectExecution(projectId: string): Promise<any> {
  const db = getDb();
  
  // Find running executions
  const runningExecutions = db.prepare(`
    SELECT id
    FROM agent_executions
    WHERE project_id = ? AND status = 'running'
  `).all(projectId) as { id: string }[];

  let stoppedCount = 0;

  for (const execution of runningExecutions) {
    const process = activeExecutions.get(execution.id);
    if (process) {
      process.kill('SIGTERM');
      activeExecutions.delete(execution.id);
      stoppedCount++;

      // Update status
      db.prepare(`
        UPDATE agent_executions
        SET status = 'cancelled', completed_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `).run(execution.id);

      emitExecutionUpdate(io, execution.id, {
        status: 'cancelled'
      });
    }
  }

  return {
    stoppedCount,
    message: `Stopped ${stoppedCount} execution(s)`
  };
}

export function getActiveExecutions(): string[] {
  return Array.from(activeExecutions.keys());
}

export function isExecutionActive(executionId: string): boolean {
  return activeExecutions.has(executionId);
}