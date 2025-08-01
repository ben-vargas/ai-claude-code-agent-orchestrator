import { Router } from 'express';
import { getDb } from '../database/db';
import { logger } from '../index';

const router = Router();

// GET /api/executions
router.get('/', (req, res) => {
  try {
    const db = getDb();
    const { status, projectId, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT e.*, p.name as project_name
      FROM agent_executions e
      LEFT JOIN projects p ON e.project_id = p.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (status) {
      query += ' AND e.status = ?';
      params.push(status);
    }

    if (projectId) {
      query += ' AND e.project_id = ?';
      params.push(projectId);
    }

    query += ' ORDER BY e.started_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const executions = db.prepare(query).all(...params);
    res.json(executions);
  } catch (error) {
    logger.error('Failed to fetch executions:', error);
    res.status(500).json({ error: 'Failed to fetch executions' });
  }
});

// GET /api/executions/:id
router.get('/:id', (req, res) => {
  try {
    const db = getDb();
    
    const execution = db.prepare(`
      SELECT e.*, p.name as project_name
      FROM agent_executions e
      LEFT JOIN projects p ON e.project_id = p.id
      WHERE e.id = ?
    `).get(req.params.id);

    if (!execution) {
      return res.status(404).json({ error: 'Execution not found' });
    }

    // Get tasks
    const tasks = db.prepare(`
      SELECT * FROM agent_tasks
      WHERE execution_id = ?
      ORDER BY started_at
    `).all(req.params.id);

    // Get logs
    const logs = db.prepare(`
      SELECT * FROM agent_logs
      WHERE execution_id = ?
      ORDER BY created_at DESC
      LIMIT 100
    `).all(req.params.id);

    res.json({
      ...execution,
      tasks,
      logs
    });
  } catch (error) {
    logger.error('Failed to fetch execution:', error);
    res.status(500).json({ error: 'Failed to fetch execution' });
  }
});

// GET /api/executions/:id/logs
router.get('/:id/logs', (req, res) => {
  try {
    const db = getDb();
    const { limit = 100, offset = 0, level, agent } = req.query;

    let query = 'SELECT * FROM agent_logs WHERE execution_id = ?';
    const params: any[] = [req.params.id];

    if (level) {
      query += ' AND level = ?';
      params.push(level);
    }

    if (agent) {
      query += ' AND agent_name = ?';
      params.push(agent);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const logs = db.prepare(query).all(...params);
    res.json(logs);
  } catch (error) {
    logger.error('Failed to fetch logs:', error);
    res.status(500).json({ error: 'Failed to fetch logs' });
  }
});

// POST /api/executions/:id/cancel
router.post('/:id/cancel', async (req, res) => {
  try {
    const db = getDb();
    
    // Update status
    db.prepare(`
      UPDATE agent_executions
      SET status = 'cancelled', completed_at = CURRENT_TIMESTAMP
      WHERE id = ? AND status = 'running'
    `).run(req.params.id);

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to cancel execution:', error);
    res.status(500).json({ error: 'Failed to cancel execution' });
  }
});

export const executionRoutes = router;