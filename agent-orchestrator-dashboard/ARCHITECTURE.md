# Agent Orchestrator Dashboard Architecture

## Overview

The Agent Orchestrator Dashboard is a comprehensive web application for monitoring and managing the Claude Code Agent Orchestrator system. It provides real-time visibility into agent executions, project management, and configuration control.

## 1. Recommended Tech Stack

### Frontend
- **Framework**: React 18+ with TypeScript
- **Build Tool**: Vite
- **UI Framework**: TailwindCSS + shadcn/ui
- **State Management**: Zustand + React Query
- **Real-time**: Socket.io-client
- **Visualization**: Recharts + React Flow
- **Routing**: React Router v6

### Backend
- **Runtime**: Node.js 20+
- **Framework**: Express.js with TypeScript
- **WebSocket**: Socket.io
- **Database**: SQLite3 (existing)
- **File Monitoring**: Chokidar
- **Logging**: Winston
- **Process Management**: PM2

### DevOps
- **Containerization**: Docker + Docker Compose
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana (optional)

## 2. Component Architecture

### Layout Components
```
AppLayout
├── Sidebar (navigation)
├── Header (user info, theme)
└── MainContent (router outlet)
```

### Page Components
1. **Dashboard** - Real-time overview
   - Active agents status grid
   - Execution metrics charts
   - Recent activity feed
   - System health indicators

2. **Projects** - Project management
   - Project list with status
   - Quick actions (start/stop/configure)
   - Project creation wizard

3. **Agents** - Agent catalog
   - Agent grid with capabilities
   - Real-time status indicators
   - Performance metrics per agent
   - Configuration editor

4. **Executions** - Execution monitoring
   - Active executions with progress
   - Execution history table
   - Detailed execution view
   - Log streaming

5. **Configuration** - Settings management
   - Global settings
   - Project-specific configs
   - MCP server management
   - Import/export functionality

6. **Flow Visualizer** - Execution graphs
   - Interactive flow diagram
   - Real-time progress overlay
   - Dependency visualization

### Feature Components
- `AgentCard` - Agent status and metrics
- `ExecutionTimeline` - Temporal view
- `MetricsChart` - Performance graphs
- `ConfigEditor` - YAML/JSON editor
- `LogViewer` - Real-time log stream
- `NotificationCenter` - Alert management

## 3. Database Schema

```sql
-- Projects table
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'inactive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    config JSON
);

-- Agent executions
CREATE TABLE agent_executions (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    agent_name TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error TEXT,
    metrics JSON,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Execution plans
CREATE TABLE execution_plans (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    plan JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent tasks
CREATE TABLE agent_tasks (
    id TEXT PRIMARY KEY,
    execution_id TEXT,
    task_id TEXT NOT NULL,
    agent_name TEXT NOT NULL,
    status TEXT NOT NULL,
    input JSON,
    output JSON,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id)
);

-- Agent logs
CREATE TABLE agent_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id TEXT,
    agent_name TEXT,
    level TEXT,
    message TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id)
);

-- Project configurations
CREATE TABLE project_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    config_type TEXT,
    config_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent configurations
CREATE TABLE agent_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    agent_name TEXT,
    config JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Execution metrics
CREATE TABLE execution_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id TEXT,
    metric_name TEXT,
    metric_value REAL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id)
);

-- MCP servers
CREATE TABLE mcp_servers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    status TEXT,
    config JSON,
    last_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Webhooks
CREATE TABLE webhooks (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    url TEXT NOT NULL,
    events JSON,
    headers JSON,
    active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent dependencies
CREATE TABLE agent_dependencies (
    id TEXT PRIMARY KEY,
    execution_plan_id TEXT,
    from_task TEXT,
    to_task TEXT,
    dependency_type TEXT,
    FOREIGN KEY (execution_plan_id) REFERENCES execution_plans(id)
);

-- Create indexes
CREATE INDEX idx_executions_project ON agent_executions(project_id);
CREATE INDEX idx_executions_status ON agent_executions(status);
CREATE INDEX idx_tasks_execution ON agent_tasks(execution_id);
CREATE INDEX idx_logs_execution ON agent_logs(execution_id);
CREATE INDEX idx_metrics_execution ON execution_metrics(execution_id);
```

## 4. API Design

### RESTful Endpoints

#### Projects
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create new project
- `GET /api/projects/:id` - Get project details
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/start` - Start project execution
- `POST /api/projects/:id/stop` - Stop project execution

#### Agents
- `GET /api/agents` - List all agents with current status
- `GET /api/agents/:name` - Get agent details
- `GET /api/agents/:name/status` - Get real-time status
- `GET /api/agents/:name/metrics` - Get performance metrics
- `PUT /api/agents/:name/config` - Update agent configuration

#### Executions
- `GET /api/executions` - List executions (with filters)
- `POST /api/executions` - Start new execution
- `GET /api/executions/:id` - Get execution details
- `GET /api/executions/:id/logs` - Stream execution logs
- `POST /api/executions/:id/cancel` - Cancel execution
- `GET /api/executions/:id/metrics` - Get execution metrics

#### Configuration
- `GET /api/config/global` - Get global configuration
- `PUT /api/config/global` - Update global configuration
- `GET /api/config/projects/:id` - Get project configuration
- `PUT /api/config/projects/:id` - Update project configuration
- `POST /api/config/export` - Export configuration
- `POST /api/config/import` - Import configuration

#### MCP Servers
- `GET /api/mcp-servers` - List MCP servers
- `GET /api/mcp-servers/:name/status` - Check server status
- `POST /api/mcp-servers/:name/restart` - Restart server

### WebSocket Events

#### Client → Server
- `subscribe:agent` - Subscribe to agent updates
- `subscribe:execution` - Subscribe to execution updates
- `subscribe:logs` - Subscribe to log stream

#### Server → Client
- `agent:status` - Agent status update
- `agent:metrics` - Agent metrics update
- `execution:started` - Execution started
- `execution:progress` - Execution progress update
- `execution:completed` - Execution completed
- `execution:failed` - Execution failed
- `log:entry` - New log entry
- `metric:update` - Metric update

## 5. Implementation Plan

### Phase 1: Foundation (Week 1)
**Agents**: orchestration-agent, backend-expert, database-architect

1. Set up project structure
2. Initialize frontend and backend
3. Implement database schema
4. Create basic API structure
5. Set up WebSocket server

### Phase 2: Core Features (Week 2-3)
**Agents**: frontend-expert, uiux-expert, backend-expert

1. Implement authentication
2. Create dashboard UI
3. Build agent management
4. Develop execution monitoring
5. Add real-time updates

### Phase 3: Advanced Features (Week 4)
**Agents**: frontend-expert, backend-expert, devops-sre-expert

1. Implement flow visualizer
2. Add configuration management
3. Create webhook system
4. Build metrics collection
5. Add import/export

### Phase 4: Integration (Week 5)
**Agents**: devops-sre-expert, qa-test-engineer

1. Modify orchestrator scripts
2. Implement file monitoring
3. Add process hooks
4. Test integrations
5. Performance optimization

### Phase 5: Testing & Deployment (Week 6)
**Agents**: qa-test-engineer, security-specialist, devops-sre-expert

1. Unit and integration tests
2. Security audit
3. Docker configuration
4. CI/CD setup
5. Documentation

## 6. Integration Points

### Orchestrator Script Modifications

```bash
# Add to orchestrator.sh
webhook_notify() {
    local event=$1
    local data=$2
    curl -X POST http://localhost:3001/api/webhooks/notify \
        -H "Content-Type: application/json" \
        -d "{\"event\": \"$event\", \"data\": $data}"
}

# Add hooks at key points
webhook_notify "execution:started" "{\"project\": \"$PROJECT_NAME\"}"
```

### File System Monitoring

```javascript
// Monitor agent workspaces
const chokidar = require('chokidar');

const watcher = chokidar.watch('~/.claude/agent-workspaces/', {
    persistent: true,
    ignoreInitial: true
});

watcher.on('change', (path) => {
    // Parse agent output and update status
    updateAgentStatus(path);
});
```

### Database Triggers

```sql
-- Notify on status changes
CREATE TRIGGER notify_execution_status
AFTER UPDATE ON agent_executions
WHEN NEW.status != OLD.status
BEGIN
    SELECT notify_webhook('execution:status', NEW.id);
END;
```

## 7. Security Considerations

1. **Authentication**: JWT-based auth with refresh tokens
2. **Authorization**: Role-based access control (RBAC)
3. **API Security**: Rate limiting, CORS, input validation
4. **Data Security**: Encrypted sensitive configurations
5. **WebSocket Security**: Token-based connection auth

## 8. Performance Optimizations

1. **Database**: Indexes on frequently queried fields
2. **Caching**: Redis for session and query caching
3. **WebSocket**: Room-based subscriptions
4. **Frontend**: React.memo, lazy loading, virtualization
5. **API**: Pagination, field filtering, response compression

## 9. Monitoring & Observability

1. **Application Metrics**: Response times, error rates
2. **Agent Metrics**: Execution times, success rates
3. **System Metrics**: CPU, memory, disk usage
4. **Logging**: Structured logs with correlation IDs
5. **Alerts**: Threshold-based notifications

## 10. Future Enhancements

1. **Machine Learning**: Predictive agent selection
2. **Automation**: Scheduled executions
3. **Collaboration**: Multi-user support
4. **Plugins**: Extensible agent system
5. **Mobile App**: Native mobile monitoring