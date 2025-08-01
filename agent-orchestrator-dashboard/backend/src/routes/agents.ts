import { Router } from 'express';
import { getAllAgentStatuses, getAgentStatus } from '../monitors/agent-monitor';
import { getDb } from '../database/db';
import { logger } from '../index';

const router = Router();

// GET /api/agents
router.get('/', (req, res) => {
  try {
    const agents = getAllAgentStatuses();
    res.json(agents);
  } catch (error) {
    logger.error('Failed to fetch agents:', error);
    res.status(500).json({ error: 'Failed to fetch agents' });
  }
});

// GET /api/agents/:name
router.get('/:name', (req, res) => {
  try {
    const agent = getAgentStatus(req.params.name);
    
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    res.json(agent);
  } catch (error) {
    logger.error('Failed to fetch agent:', error);
    res.status(500).json({ error: 'Failed to fetch agent' });
  }
});

// GET /api/agents/:name/status
router.get('/:name/status', (req, res) => {
  try {
    const agent = getAgentStatus(req.params.name);
    
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    res.json({
      name: agent.name,
      status: agent.status,
      lastSeen: agent.lastSeen,
      currentExecution: agent.currentExecution
    });
  } catch (error) {
    logger.error('Failed to fetch agent status:', error);
    res.status(500).json({ error: 'Failed to fetch agent status' });
  }
});

// GET /api/agents/:name/metrics
router.get('/:name/metrics', (req, res) => {
  try {
    const db = getDb();
    const { name } = req.params;
    const { days = 7 } = req.query;

    const metrics = db.prepare(`
      SELECT 
        DATE(started_at) as date,
        COUNT(*) as executions,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed,
        AVG(CASE 
          WHEN completed_at IS NOT NULL 
          THEN (julianday(completed_at) - julianday(started_at)) * 24 * 60 * 60
          ELSE NULL 
        END) as avg_duration
      FROM agent_executions
      WHERE agent_name = ? 
        AND started_at > datetime('now', '-' || ? || ' days')
      GROUP BY DATE(started_at)
      ORDER BY date DESC
    `).all(name, days);

    res.json(metrics);
  } catch (error) {
    logger.error('Failed to fetch agent metrics:', error);
    res.status(500).json({ error: 'Failed to fetch agent metrics' });
  }
});

// PUT /api/agents/:name/config
router.put('/:name/config', async (req, res) => {
  try {
    const db = getDb();
    const { name } = req.params;
    const { projectId, config } = req.body;

    // Validate agent exists
    const agent = getAgentStatus(name);
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    // Update or insert configuration
    const existing = db.prepare(`
      SELECT id FROM agent_configurations
      WHERE agent_name = ? AND project_id = ?
    `).get(name, projectId || 'global');

    if (existing) {
      db.prepare(`
        UPDATE agent_configurations
        SET config = ?, created_at = CURRENT_TIMESTAMP
        WHERE agent_name = ? AND project_id = ?
      `).run(JSON.stringify(config), name, projectId || 'global');
    } else {
      const id = require('uuid').v4();
      db.prepare(`
        INSERT INTO agent_configurations (id, project_id, agent_name, config)
        VALUES (?, ?, ?, ?)
      `).run(id, projectId || 'global', name, JSON.stringify(config));
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to update agent config:', error);
    res.status(500).json({ error: 'Failed to update agent config' });
  }
});

export const agentRoutes = router;