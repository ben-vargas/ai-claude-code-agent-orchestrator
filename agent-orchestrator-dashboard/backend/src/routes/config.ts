import { Router } from 'express';
import { getDb } from '../database/db';
import { logger } from '../index';
import { config as appConfig } from '../config';

const router = Router();

// GET /api/config/global
router.get('/global', (req, res) => {
  try {
    const db = getDb();
    
    const globalConfig = db.prepare(`
      SELECT * FROM project_configurations
      WHERE project_id = 'global'
    `).all();

    const configMap = globalConfig.reduce((acc, cfg) => {
      acc[cfg.config_type] = JSON.parse(cfg.config_data);
      return acc;
    }, {});

    res.json({
      ...configMap,
      defaults: {
        maxParallelTerminals: appConfig.orchestrator.maxParallelTerminals,
        defaultTimeoutMinutes: appConfig.orchestrator.defaultTimeoutMinutes,
      }
    });
  } catch (error) {
    logger.error('Failed to fetch global config:', error);
    res.status(500).json({ error: 'Failed to fetch global config' });
  }
});

// PUT /api/config/global
router.put('/global', (req, res) => {
  try {
    const db = getDb();
    const { configType, configData } = req.body;

    const existing = db.prepare(`
      SELECT id FROM project_configurations
      WHERE project_id = 'global' AND config_type = ?
    `).get(configType);

    if (existing) {
      db.prepare(`
        UPDATE project_configurations
        SET config_data = ?, created_at = CURRENT_TIMESTAMP
        WHERE project_id = 'global' AND config_type = ?
      `).run(JSON.stringify(configData), configType);
    } else {
      const id = require('uuid').v4();
      db.prepare(`
        INSERT INTO project_configurations (id, project_id, config_type, config_data)
        VALUES (?, 'global', ?, ?)
      `).run(id, configType, JSON.stringify(configData));
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to update global config:', error);
    res.status(500).json({ error: 'Failed to update global config' });
  }
});

// GET /api/config/projects/:id
router.get('/projects/:id', (req, res) => {
  try {
    const db = getDb();
    
    const projectConfig = db.prepare(`
      SELECT * FROM project_configurations
      WHERE project_id = ?
    `).all(req.params.id);

    const configMap = projectConfig.reduce((acc, cfg) => {
      acc[cfg.config_type] = JSON.parse(cfg.config_data);
      return acc;
    }, {});

    res.json(configMap);
  } catch (error) {
    logger.error('Failed to fetch project config:', error);
    res.status(500).json({ error: 'Failed to fetch project config' });
  }
});

// PUT /api/config/projects/:id
router.put('/projects/:id', (req, res) => {
  try {
    const db = getDb();
    const { configType, configData } = req.body;

    const existing = db.prepare(`
      SELECT id FROM project_configurations
      WHERE project_id = ? AND config_type = ?
    `).get(req.params.id, configType);

    if (existing) {
      db.prepare(`
        UPDATE project_configurations
        SET config_data = ?, created_at = CURRENT_TIMESTAMP
        WHERE project_id = ? AND config_type = ?
      `).run(JSON.stringify(configData), req.params.id, configType);
    } else {
      const id = require('uuid').v4();
      db.prepare(`
        INSERT INTO project_configurations (id, project_id, config_type, config_data)
        VALUES (?, ?, ?, ?)
      `).run(id, req.params.id, configType, JSON.stringify(configData));
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to update project config:', error);
    res.status(500).json({ error: 'Failed to update project config' });
  }
});

// POST /api/config/export
router.post('/export', (req, res) => {
  try {
    const db = getDb();
    const { projectId } = req.body;

    const configs = db.prepare(`
      SELECT * FROM project_configurations
      WHERE project_id = ?
    `).all(projectId || 'global');

    const agentConfigs = db.prepare(`
      SELECT * FROM agent_configurations
      WHERE project_id = ?
    `).all(projectId || 'global');

    const exportData = {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      projectId: projectId || 'global',
      configurations: configs,
      agentConfigurations: agentConfigs
    };

    res.json(exportData);
  } catch (error) {
    logger.error('Failed to export config:', error);
    res.status(500).json({ error: 'Failed to export config' });
  }
});

// POST /api/config/import
router.post('/import', (req, res) => {
  try {
    const db = getDb();
    const { data, targetProjectId } = req.body;

    // Validate import data
    if (!data.version || !data.configurations) {
      return res.status(400).json({ error: 'Invalid import data' });
    }

    // Import configurations
    const importedConfigs = 0;
    const importedAgentConfigs = 0;

    // TODO: Implement actual import logic with conflict resolution

    res.json({
      success: true,
      imported: {
        configurations: importedConfigs,
        agentConfigurations: importedAgentConfigs
      }
    });
  } catch (error) {
    logger.error('Failed to import config:', error);
    res.status(500).json({ error: 'Failed to import config' });
  }
});

export const configRoutes = router;