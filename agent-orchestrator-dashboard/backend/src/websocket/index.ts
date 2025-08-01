import { Server, Socket } from 'socket.io';
import { logger } from '../index';
import { verifyToken } from '../services/auth';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  projectId?: string;
}

export function setupWebSocketHandlers(io: Server): void {
  // Authentication middleware
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const user = await verifyToken(token);
      if (!user) {
        return next(new Error('Invalid token'));
      }

      socket.userId = user.id;
      next();
    } catch (error) {
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', (socket: AuthenticatedSocket) => {
    logger.info(`Client connected: ${socket.id}, User: ${socket.userId}`);

    // Join user's personal room
    socket.join(`user:${socket.userId}`);

    // Subscribe to agent updates
    socket.on('subscribe:agent', (agentName: string) => {
      socket.join(`agent:${agentName}`);
      logger.info(`Socket ${socket.id} subscribed to agent ${agentName}`);
    });

    // Subscribe to execution updates
    socket.on('subscribe:execution', (executionId: string) => {
      socket.join(`execution:${executionId}`);
      logger.info(`Socket ${socket.id} subscribed to execution ${executionId}`);
    });

    // Subscribe to project updates
    socket.on('subscribe:project', (projectId: string) => {
      socket.join(`project:${projectId}`);
      socket.projectId = projectId;
      logger.info(`Socket ${socket.id} subscribed to project ${projectId}`);
    });

    // Subscribe to log stream
    socket.on('subscribe:logs', (filters: { executionId?: string; agentName?: string }) => {
      if (filters.executionId) {
        socket.join(`logs:execution:${filters.executionId}`);
      }
      if (filters.agentName) {
        socket.join(`logs:agent:${filters.agentName}`);
      }
      logger.info(`Socket ${socket.id} subscribed to logs`, filters);
    });

    // Unsubscribe handlers
    socket.on('unsubscribe:agent', (agentName: string) => {
      socket.leave(`agent:${agentName}`);
    });

    socket.on('unsubscribe:execution', (executionId: string) => {
      socket.leave(`execution:${executionId}`);
    });

    socket.on('unsubscribe:project', (projectId: string) => {
      socket.leave(`project:${projectId}`);
      socket.projectId = undefined;
    });

    socket.on('disconnect', () => {
      logger.info(`Client disconnected: ${socket.id}`);
    });
  });

  // Periodic ping to keep connections alive
  setInterval(() => {
    io.emit('ping', { timestamp: Date.now() });
  }, 30000);
}

// Helper functions to emit events
export function emitAgentStatus(io: Server, agentName: string, status: any): void {
  io.to(`agent:${agentName}`).emit('agent:status', {
    agentName,
    status,
    timestamp: new Date().toISOString()
  });
}

export function emitExecutionUpdate(io: Server, executionId: string, update: any): void {
  io.to(`execution:${executionId}`).emit('execution:update', {
    executionId,
    ...update,
    timestamp: new Date().toISOString()
  });
}

export function emitProjectUpdate(io: Server, projectId: string, update: any): void {
  io.to(`project:${projectId}`).emit('project:update', {
    projectId,
    ...update,
    timestamp: new Date().toISOString()
  });
}

export function emitLogEntry(io: Server, log: any): void {
  if (log.executionId) {
    io.to(`logs:execution:${log.executionId}`).emit('log:entry', log);
  }
  if (log.agentName) {
    io.to(`logs:agent:${log.agentName}`).emit('log:entry', log);
  }
}

export function emitMetricUpdate(io: Server, metric: any): void {
  if (metric.executionId) {
    io.to(`execution:${metric.executionId}`).emit('metric:update', metric);
  }
  if (metric.projectId) {
    io.to(`project:${metric.projectId}`).emit('metric:update', metric);
  }
}