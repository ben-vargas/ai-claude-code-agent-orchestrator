import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import Joi from 'joi';
import { getDb } from '../database/db';
import { logger } from '../index';
import { validateRequest } from '../middleware/validation';
import { startProjectExecution, stopProjectExecution } from '../services/orchestrator';

const router = Router();

const projectSchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  description: Joi.string().optional().max(500),
  config: Joi.object().optional()
});

// GET /api/projects
router.get('/', (req, res) => {
  try {
    const db = getDb();
    const projects = db.prepare(`
      SELECT p.*, 
        COUNT(DISTINCT ae.id) as execution_count,
        COUNT(DISTINCT CASE WHEN ae.status = 'running' THEN ae.id END) as running_count
      FROM projects p
      LEFT JOIN agent_executions ae ON p.id = ae.project_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    `).all();

    res.json(projects);
  } catch (error) {
    logger.error('Failed to fetch projects:', error);
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// POST /api/projects
router.post('/', validateRequest(projectSchema), (req, res) => {
  try {
    const db = getDb();
    const id = uuidv4();
    const { name, description, config } = req.body;

    const result = db.prepare(`
      INSERT INTO projects (id, name, description, config)
      VALUES (?, ?, ?, ?)
    `).run(id, name, description, JSON.stringify(config || {}));

    const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
    
    res.status(201).json(project);
  } catch (error) {
    logger.error('Failed to create project:', error);
    res.status(500).json({ error: 'Failed to create project' });
  }
});

// GET /api/projects/:id
router.get('/:id', (req, res) => {
  try {
    const db = getDb();
    const project = db.prepare(`
      SELECT p.*, 
        COUNT(DISTINCT ae.id) as execution_count,
        COUNT(DISTINCT CASE WHEN ae.status = 'running' THEN ae.id END) as running_count
      FROM projects p
      LEFT JOIN agent_executions ae ON p.id = ae.project_id
      WHERE p.id = ?
      GROUP BY p.id
    `).get(req.params.id);

    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    res.json(project);
  } catch (error) {
    logger.error('Failed to fetch project:', error);
    res.status(500).json({ error: 'Failed to fetch project' });
  }
});

// PUT /api/projects/:id
router.put('/:id', validateRequest(projectSchema), (req, res) => {
  try {
    const db = getDb();
    const { name, description, config } = req.body;

    const result = db.prepare(`
      UPDATE projects 
      SET name = ?, description = ?, config = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(name, description, JSON.stringify(config || {}), req.params.id);

    if (result.changes === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
    res.json(project);
  } catch (error) {
    logger.error('Failed to update project:', error);
    res.status(500).json({ error: 'Failed to update project' });
  }
});

// DELETE /api/projects/:id
router.delete('/:id', (req, res) => {
  try {
    const db = getDb();
    
    // Check for running executions
    const runningCount = db.prepare(`
      SELECT COUNT(*) as count
      FROM agent_executions
      WHERE project_id = ? AND status = 'running'
    `).get(req.params.id) as { count: number };

    if (runningCount.count > 0) {
      return res.status(400).json({ error: 'Cannot delete project with running executions' });
    }

    const result = db.prepare('DELETE FROM projects WHERE id = ?').run(req.params.id);

    if (result.changes === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    res.status(204).send();
  } catch (error) {
    logger.error('Failed to delete project:', error);
    res.status(500).json({ error: 'Failed to delete project' });
  }
});

// POST /api/projects/:id/start
router.post('/:id/start', async (req, res) => {
  try {
    const db = getDb();
    const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);

    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const execution = await startProjectExecution(req.params.id, req.body);
    res.json(execution);
  } catch (error) {
    logger.error('Failed to start project execution:', error);
    res.status(500).json({ error: 'Failed to start project execution' });
  }
});

// POST /api/projects/:id/stop
router.post('/:id/stop', async (req, res) => {
  try {
    const result = await stopProjectExecution(req.params.id);
    res.json(result);
  } catch (error) {
    logger.error('Failed to stop project execution:', error);
    res.status(500).json({ error: 'Failed to stop project execution' });
  }
});

export const projectRoutes = router;