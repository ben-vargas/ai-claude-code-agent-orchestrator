import { Express } from 'express';
import { projectRoutes } from './projects';
import { agentRoutes } from './agents';
import { executionRoutes } from './executions';
import { configRoutes } from './config';
import { mcpServerRoutes } from './mcp-servers';
import { webhookRoutes } from './webhooks';
import { authRoutes } from './auth';
import { authMiddleware } from '../middleware/auth';

export function setupRoutes(app: Express): void {
  // Public routes
  app.use('/api/auth', authRoutes);
  app.use('/api/webhooks', webhookRoutes);

  // Protected routes
  app.use('/api/projects', authMiddleware, projectRoutes);
  app.use('/api/agents', authMiddleware, agentRoutes);
  app.use('/api/executions', authMiddleware, executionRoutes);
  app.use('/api/config', authMiddleware, configRoutes);
  app.use('/api/mcp-servers', authMiddleware, mcpServerRoutes);

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  // Error handler
  app.use((err: any, req: any, res: any, next: any) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
      error: err.message || 'Internal server error',
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
  });
}