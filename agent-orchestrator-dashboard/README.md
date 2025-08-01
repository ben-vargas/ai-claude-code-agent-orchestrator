# Agent Orchestrator Dashboard

A comprehensive web application for monitoring and managing the Claude Code Agent Orchestrator system.

## Features

### Real-time Monitoring
- Live agent status tracking across all 24 agents
- Execution progress visualization
- Real-time log streaming
- WebSocket-based updates

### Project Management
- Create and manage multiple projects
- Start/stop orchestrator executions
- Configure project-specific settings
- Track execution history

### Agent Management
- View agent capabilities and performance metrics
- Configure agent-specific settings per project
- Monitor agent collaboration patterns
- Track success rates and execution times

### Execution Visualization
- Interactive flow diagrams with React Flow
- Dependency tracking and visualization
- Real-time progress overlays
- Execution timeline views

### Configuration Management
- Global and project-specific settings
- MCP server management
- Import/export configurations
- Rule profile management

## Tech Stack

### Backend
- Node.js 20+ with TypeScript
- Express.js for REST API
- Socket.io for real-time communication
- SQLite3 with better-sqlite3
- JWT authentication
- Chokidar for file monitoring

### Frontend
- React 18 with TypeScript
- Vite for fast development
- TailwindCSS + shadcn/ui
- TanStack Query for data fetching
- Zustand for state management
- Recharts for metrics visualization
- React Flow for execution graphs

## Installation

1. Install dependencies:
```bash
# Backend
cd backend
npm install

# Frontend
cd ../frontend
npm install
```

2. Set up environment variables:
```bash
# Backend (.env)
PORT=3001
JWT_SECRET=your-secret-key
FRONTEND_URL=http://localhost:5173

# Frontend (.env)
VITE_API_URL=http://localhost:3001
```

3. Run database migrations:
```bash
cd backend
npm run db:migrate
```

4. Start the servers:
```bash
# Backend (in one terminal)
cd backend
npm run dev

# Frontend (in another terminal)
cd frontend
npm run dev
```

5. Access the dashboard at http://localhost:5173

## Default Credentials

On first run, create an admin user:
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "email": "admin@example.com", "password": "changeme"}'
```

## Integration with Orchestrator

The dashboard integrates with the orchestrator scripts through:

1. **Webhook Integration**: Add to orchestrator.sh
```bash
export WEBHOOK_URL="http://localhost:3001/api/webhooks/notify"
export EXECUTION_ID="unique-execution-id"
export PROJECT_ID="project-id"
```

2. **File Monitoring**: The dashboard monitors:
- `~/.claude/agent-workspaces/Agent-*.md` files
- Orchestrator log files

3. **Process Hooks**: The orchestrator sends events:
- execution:started
- agent:started
- agent:completed
- execution:completed

## API Endpoints

### Projects
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create new project
- `GET /api/projects/:id` - Get project details
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/start` - Start execution
- `POST /api/projects/:id/stop` - Stop execution

### Agents
- `GET /api/agents` - List all agents with status
- `GET /api/agents/:name` - Get agent details
- `GET /api/agents/:name/status` - Get real-time status
- `GET /api/agents/:name/metrics` - Get performance metrics
- `PUT /api/agents/:name/config` - Update configuration

### Executions
- `GET /api/executions` - List executions
- `GET /api/executions/:id` - Get execution details
- `GET /api/executions/:id/logs` - Stream logs
- `POST /api/executions/:id/cancel` - Cancel execution

### Configuration
- `GET /api/config/global` - Get global config
- `PUT /api/config/global` - Update global config
- `GET /api/config/projects/:id` - Get project config
- `PUT /api/config/projects/:id` - Update project config
- `POST /api/config/export` - Export configuration
- `POST /api/config/import` - Import configuration

## WebSocket Events

### Client → Server
- `subscribe:agent` - Subscribe to agent updates
- `subscribe:execution` - Subscribe to execution updates
- `subscribe:project` - Subscribe to project updates
- `subscribe:logs` - Subscribe to log stream

### Server → Client
- `agent:status` - Agent status update
- `execution:update` - Execution progress
- `project:update` - Project changes
- `log:entry` - New log entry
- `metric:update` - Metric update

## Development

### Running Tests
```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test
```

### Building for Production
```bash
# Backend
cd backend
npm run build

# Frontend
cd frontend
npm run build
```

### Docker Deployment
```bash
# Build and run with Docker Compose
docker-compose up -d
```

## Security Considerations

1. **Authentication**: JWT-based with secure token storage
2. **Authorization**: Role-based access control (RBAC)
3. **Input Validation**: Joi schemas for all inputs
4. **Rate Limiting**: Configurable per-endpoint limits
5. **CORS**: Restricted to frontend origin
6. **WebSocket Security**: Token-based authentication

## Performance Optimization

1. **Database**: Indexes on frequently queried fields
2. **Caching**: Query caching with TanStack Query
3. **WebSocket**: Room-based subscriptions
4. **Frontend**: React.memo, lazy loading, virtualization
5. **API**: Pagination, field filtering, response compression

## Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check CORS settings
   - Verify authentication token
   - Check firewall/proxy settings

2. **Database Locked**
   - Ensure single process access
   - Check WAL mode is enabled

3. **File Monitoring Not Working**
   - Verify file permissions
   - Check path configurations
   - Ensure chokidar is installed

### Debug Mode

Enable debug logging:
```bash
# Backend
DEBUG=* npm run dev

# Frontend
VITE_DEBUG=true npm run dev
```

## Contributing

1. Follow the existing code style
2. Add tests for new features
3. Update documentation
4. Submit PR with clear description

## License

Same as parent project