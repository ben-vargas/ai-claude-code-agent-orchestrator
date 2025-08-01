import { Router } from 'express';
import { exec } from 'child_process';
import { promisify } from 'util';
import { getDb } from '../database/db';
import { logger } from '../index';

const router = Router();
const execAsync = promisify(exec);

// GET /api/mcp-servers
router.get('/', async (req, res) => {
  try {
    const db = getDb();
    
    // Get stored server status
    const servers = db.prepare('SELECT * FROM mcp_servers').all();
    
    // Check actual status for each server
    const serversWithStatus = await Promise.all(
      servers.map(async (server) => {
        const status = await checkMCPServerStatus(server.name);
        
        // Update database
        db.prepare(`
          UPDATE mcp_servers 
          SET status = ?, last_check = CURRENT_TIMESTAMP
          WHERE id = ?
        `).run(status, server.id);
        
        return {
          ...server,
          status,
          lastCheck: new Date().toISOString()
        };
      })
    );

    res.json(serversWithStatus);
  } catch (error) {
    logger.error('Failed to fetch MCP servers:', error);
    res.status(500).json({ error: 'Failed to fetch MCP servers' });
  }
});

// GET /api/mcp-servers/:name/status
router.get('/:name/status', async (req, res) => {
  try {
    const status = await checkMCPServerStatus(req.params.name);
    res.json({ name: req.params.name, status });
  } catch (error) {
    logger.error('Failed to check MCP server status:', error);
    res.status(500).json({ error: 'Failed to check MCP server status' });
  }
});

// POST /api/mcp-servers/:name/restart
router.post('/:name/restart', async (req, res) => {
  try {
    // This would integrate with the MCP server manager script
    const result = await restartMCPServer(req.params.name);
    res.json({ success: result });
  } catch (error) {
    logger.error('Failed to restart MCP server:', error);
    res.status(500).json({ error: 'Failed to restart MCP server' });
  }
});

async function checkMCPServerStatus(serverName: string): Promise<string> {
  try {
    // Check if the MCP server process is running
    const { stdout } = await execAsync(`ps aux | grep -v grep | grep "mcp.*${serverName}"`);
    return stdout ? 'running' : 'stopped';
  } catch (error) {
    return 'error';
  }
}

async function restartMCPServer(serverName: string): Promise<boolean> {
  try {
    // Call the MCP server manager script
    const scriptPath = '../../scripts/mcp-server-manager.sh';
    await execAsync(`${scriptPath} --restart ${serverName}`);
    return true;
  } catch (error) {
    logger.error(`Failed to restart MCP server ${serverName}:`, error);
    return false;
  }
}

export const mcpServerRoutes = router;