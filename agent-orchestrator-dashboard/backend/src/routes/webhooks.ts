import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../database/db';
import { logger } from '../index';
import { io } from '../index';
import { emitExecutionUpdate, emitAgentStatus, emitLogEntry, emitMetricUpdate } from '../websocket';

const router = Router();

// POST /api/webhooks/notify
router.post('/notify', (req, res) => {
  try {
    const { event, data, executionId, projectId } = req.body;

    logger.info(`Webhook received: ${event}`, { executionId, projectId });

    // Handle different event types
    switch (event) {
      case 'execution:started':
        handleExecutionStarted(data);
        break;
      case 'execution:progress':
        handleExecutionProgress(data);
        break;
      case 'execution:completed':
        handleExecutionCompleted(data);
        break;
      case 'agent:started':
        handleAgentStarted(data);
        break;
      case 'agent:completed':
        handleAgentCompleted(data);
        break;
      case 'agent:log':
        handleAgentLog(data);
        break;
      case 'metric:update':
        handleMetricUpdate(data);
        break;
      default:
        logger.warn(`Unknown webhook event: ${event}`);
    }

    res.json({ received: true });
  } catch (error) {
    logger.error('Webhook processing failed:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// GET /api/webhooks (list webhooks)
router.get('/', (req, res) => {
  try {
    const db = getDb();
    const webhooks = db.prepare(`
      SELECT w.*, p.name as project_name
      FROM webhooks w
      LEFT JOIN projects p ON w.project_id = p.id
      WHERE w.active = 1
      ORDER BY w.created_at DESC
    `).all();

    res.json(webhooks);
  } catch (error) {
    logger.error('Failed to fetch webhooks:', error);
    res.status(500).json({ error: 'Failed to fetch webhooks' });
  }
});

// POST /api/webhooks (create webhook)
router.post('/', (req, res) => {
  try {
    const db = getDb();
    const { projectId, url, events, headers } = req.body;
    const id = uuidv4();

    db.prepare(`
      INSERT INTO webhooks (id, project_id, url, events, headers)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      id,
      projectId,
      url,
      JSON.stringify(events || ['*']),
      JSON.stringify(headers || {})
    );

    res.status(201).json({ id, url, events });
  } catch (error) {
    logger.error('Failed to create webhook:', error);
    res.status(500).json({ error: 'Failed to create webhook' });
  }
});

// Event handlers
function handleExecutionStarted(data: any): void {
  const db = getDb();
  const { executionId, projectId, plan } = data;

  if (plan) {
    db.prepare(`
      INSERT INTO execution_plans (id, project_id, plan)
      VALUES (?, ?, ?)
    `).run(uuidv4(), projectId, JSON.stringify(plan));
  }

  emitExecutionUpdate(io, executionId, {
    status: 'started',
    plan
  });
}

function handleExecutionProgress(data: any): void {
  const { executionId, progress, currentAgent, completedAgents } = data;

  emitExecutionUpdate(io, executionId, {
    status: 'progress',
    progress,
    currentAgent,
    completedAgents
  });
}

function handleExecutionCompleted(data: any): void {
  const db = getDb();
  const { executionId, status, summary } = data;

  db.prepare(`
    UPDATE agent_executions
    SET status = ?, completed_at = CURRENT_TIMESTAMP, metrics = ?
    WHERE id = ?
  `).run(status, JSON.stringify(summary || {}), executionId);

  emitExecutionUpdate(io, executionId, {
    status: 'completed',
    summary
  });
}

function handleAgentStarted(data: any): void {
  const db = getDb();
  const { agentName, taskId, executionId, input } = data;

  const id = uuidv4();
  db.prepare(`
    INSERT INTO agent_tasks (id, execution_id, task_id, agent_name, status, input, started_at)
    VALUES (?, ?, ?, ?, 'running', ?, CURRENT_TIMESTAMP)
  `).run(id, executionId, taskId, agentName, JSON.stringify(input || {}));

  emitAgentStatus(io, agentName, {
    status: 'running',
    currentTask: taskId,
    executionId
  });
}

function handleAgentCompleted(data: any): void {
  const db = getDb();
  const { agentName, taskId, executionId, status, output } = data;

  db.prepare(`
    UPDATE agent_tasks
    SET status = ?, output = ?, completed_at = CURRENT_TIMESTAMP
    WHERE execution_id = ? AND task_id = ?
  `).run(status, JSON.stringify(output || {}), executionId, taskId);

  emitAgentStatus(io, agentName, {
    status: 'idle',
    lastTask: taskId,
    lastStatus: status
  });
}

function handleAgentLog(data: any): void {
  const db = getDb();
  const { executionId, agentName, level, message, metadata } = data;

  db.prepare(`
    INSERT INTO agent_logs (execution_id, agent_name, level, message, metadata)
    VALUES (?, ?, ?, ?, ?)
  `).run(
    executionId,
    agentName,
    level || 'info',
    message,
    JSON.stringify(metadata || {})
  );

  emitLogEntry(io, {
    executionId,
    agentName,
    level: level || 'info',
    message,
    metadata
  });
}

function handleMetricUpdate(data: any): void {
  const db = getDb();
  const { executionId, metricName, metricValue } = data;

  db.prepare(`
    INSERT INTO execution_metrics (execution_id, metric_name, metric_value)
    VALUES (?, ?, ?)
  `).run(executionId, metricName, metricValue);

  emitMetricUpdate(io, {
    executionId,
    metricName,
    metricValue
  });
}

export const webhookRoutes = router;