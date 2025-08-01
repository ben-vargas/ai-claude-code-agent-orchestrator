import chokidar from 'chokidar';
import { Server } from 'socket.io';
import { readFileSync } from 'fs';
import { join, basename } from 'path';
import { config } from '../config';
import { logger } from '../index';
import { getDb } from '../database/db';
import { emitAgentStatus, emitLogEntry } from '../websocket';

interface AgentWorkspaceUpdate {
  agent: string;
  taskId?: string;
  status?: string;
  outputs?: any;
  timestamp: string;
}

export function startFileMonitor(io: Server): void {
  const workspacePath = config.paths.agentWorkspaces;
  
  logger.info(`Starting file monitor for: ${workspacePath}`);

  const watcher = chokidar.watch(`${workspacePath}/Agent-*.md`, {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: {
      stabilityThreshold: 1000,
      pollInterval: 100
    }
  });

  watcher.on('change', (path) => {
    handleWorkspaceChange(io, path);
  });

  watcher.on('add', (path) => {
    logger.info(`New agent workspace detected: ${path}`);
    handleWorkspaceChange(io, path);
  });

  watcher.on('error', (error) => {
    logger.error('File monitor error:', error);
  });

  // Also monitor orchestrator logs
  const logWatcher = chokidar.watch(`${config.paths.orchestratorLogs}/*.log`, {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: {
      stabilityThreshold: 500,
      pollInterval: 100
    }
  });

  logWatcher.on('change', (path) => {
    handleLogChange(io, path);
  });
}

function handleWorkspaceChange(io: Server, filePath: string): void {
  try {
    const fileName = basename(filePath);
    const agentName = fileName.replace('Agent-', '').replace('.md', '').toLowerCase();
    
    const content = readFileSync(filePath, 'utf8');
    const update = parseAgentWorkspace(content, agentName);
    
    if (update) {
      // Update database
      updateAgentStatus(agentName, update);
      
      // Emit websocket event
      emitAgentStatus(io, agentName, {
        status: update.status || 'active',
        lastUpdate: update.timestamp,
        currentTask: update.taskId,
        outputs: update.outputs
      });
    }
  } catch (error) {
    logger.error(`Error processing workspace file ${filePath}:`, error);
  }
}

function parseAgentWorkspace(content: string, agentName: string): AgentWorkspaceUpdate | null {
  try {
    // Extract JSON blocks from markdown
    const jsonMatches = content.match(/```json\n([\s\S]*?)\n```/g);
    if (!jsonMatches || jsonMatches.length === 0) {
      return null;
    }

    // Get the latest JSON block
    const latestJson = jsonMatches[jsonMatches.length - 1];
    const jsonContent = latestJson.replace(/```json\n|\n```/g, '');
    const data = JSON.parse(jsonContent);

    return {
      agent: agentName,
      taskId: data.taskId,
      status: data.status,
      outputs: data.outputs,
      timestamp: data.timestamp || new Date().toISOString()
    };
  } catch (error) {
    logger.debug(`Could not parse JSON from agent workspace: ${error}`);
    
    // Fallback: extract status from markdown
    const statusMatch = content.match(/Status:\s*(\w+)/i);
    const taskMatch = content.match(/Task ID:\s*(\S+)/i);
    
    if (statusMatch || taskMatch) {
      return {
        agent: agentName,
        status: statusMatch?.[1],
        taskId: taskMatch?.[1],
        timestamp: new Date().toISOString()
      };
    }
    
    return null;
  }
}

function updateAgentStatus(agentName: string, update: AgentWorkspaceUpdate): void {
  try {
    const db = getDb();
    
    // Find active execution for this agent
    const execution = db.prepare(`
      SELECT id, project_id 
      FROM agent_executions 
      WHERE agent_name = ? AND status = 'running'
      ORDER BY started_at DESC
      LIMIT 1
    `).get(agentName) as { id: string; project_id: string } | undefined;

    if (execution) {
      // Update execution status if completed
      if (update.status === 'completed' || update.status === 'failed') {
        db.prepare(`
          UPDATE agent_executions
          SET status = ?, completed_at = CURRENT_TIMESTAMP, metrics = ?
          WHERE id = ?
        `).run(
          update.status,
          JSON.stringify(update.outputs?.metrics || {}),
          execution.id
        );
      }

      // Log the update
      if (update.outputs?.deliverables) {
        db.prepare(`
          INSERT INTO agent_logs (execution_id, agent_name, level, message, metadata)
          VALUES (?, ?, ?, ?, ?)
        `).run(
          execution.id,
          agentName,
          'info',
          'Agent delivered outputs',
          JSON.stringify(update.outputs)
        );
      }
    }
  } catch (error) {
    logger.error('Failed to update agent status in database:', error);
  }
}

function handleLogChange(io: Server, filePath: string): void {
  try {
    // Read last N lines of log file
    const content = readFileSync(filePath, 'utf8');
    const lines = content.split('\n').slice(-10); // Last 10 lines
    
    lines.forEach(line => {
      if (line.trim()) {
        const logEntry = parseLogLine(line);
        if (logEntry) {
          emitLogEntry(io, logEntry);
        }
      }
    });
  } catch (error) {
    logger.error(`Error processing log file ${filePath}:`, error);
  }
}

function parseLogLine(line: string): any {
  try {
    // Try to parse as JSON first
    if (line.startsWith('{')) {
      return JSON.parse(line);
    }
    
    // Otherwise parse as text log
    const timestampMatch = line.match(/^\[([\d-T:.]+)\]/);
    const levelMatch = line.match(/\[(INFO|WARN|ERROR|DEBUG)\]/);
    const agentMatch = line.match(/\[([a-z-]+)\]/);
    
    return {
      timestamp: timestampMatch?.[1] || new Date().toISOString(),
      level: levelMatch?.[1]?.toLowerCase() || 'info',
      agentName: agentMatch?.[1],
      message: line.replace(/^\[[\d-T:.]+\]\s*(\[(INFO|WARN|ERROR|DEBUG)\])?\s*(\[[a-z-]+\])?\s*/, '')
    };
  } catch (error) {
    return null;
  }
}