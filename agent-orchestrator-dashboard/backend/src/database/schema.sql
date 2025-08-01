-- Agent Orchestrator Dashboard Database Schema
-- SQLite3 Database

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'inactive' CHECK(status IN ('active', 'inactive', 'completed', 'failed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    config JSON
);

-- Agent executions
CREATE TABLE IF NOT EXISTS agent_executions (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    agent_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error TEXT,
    metrics JSON,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Execution plans
CREATE TABLE IF NOT EXISTS execution_plans (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    plan JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Agent tasks
CREATE TABLE IF NOT EXISTS agent_tasks (
    id TEXT PRIMARY KEY,
    execution_id TEXT,
    task_id TEXT NOT NULL,
    agent_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending', 'in_progress', 'completed', 'failed', 'blocked')),
    input JSON,
    output JSON,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id) ON DELETE CASCADE
);

-- Agent logs
CREATE TABLE IF NOT EXISTS agent_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id TEXT,
    agent_name TEXT,
    level TEXT CHECK(level IN ('error', 'warn', 'info', 'debug')),
    message TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id) ON DELETE CASCADE
);

-- Project configurations
CREATE TABLE IF NOT EXISTS project_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    config_type TEXT CHECK(config_type IN ('rules', 'tools', 'mcp_servers', 'agents', 'general')),
    config_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Agent configurations
CREATE TABLE IF NOT EXISTS agent_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    agent_name TEXT,
    config JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Execution metrics
CREATE TABLE IF NOT EXISTS execution_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id TEXT,
    metric_name TEXT,
    metric_value REAL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id) ON DELETE CASCADE
);

-- MCP servers
CREATE TABLE IF NOT EXISTS mcp_servers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    status TEXT CHECK(status IN ('running', 'stopped', 'error', 'unknown')),
    config JSON,
    last_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Webhooks
CREATE TABLE IF NOT EXISTS webhooks (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    url TEXT NOT NULL,
    events JSON,
    headers JSON,
    active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Agent dependencies
CREATE TABLE IF NOT EXISTS agent_dependencies (
    id TEXT PRIMARY KEY,
    execution_plan_id TEXT,
    from_task TEXT,
    to_task TEXT,
    dependency_type TEXT CHECK(dependency_type IN ('blocks', 'requires', 'optional')),
    FOREIGN KEY (execution_plan_id) REFERENCES execution_plans(id) ON DELETE CASCADE
);

-- Users (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'viewer' CHECK(role IN ('admin', 'operator', 'viewer')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_executions_project ON agent_executions(project_id);
CREATE INDEX IF NOT EXISTS idx_executions_status ON agent_executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_agent ON agent_executions(agent_name);
CREATE INDEX IF NOT EXISTS idx_tasks_execution ON agent_tasks(execution_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON agent_tasks(status);
CREATE INDEX IF NOT EXISTS idx_logs_execution ON agent_logs(execution_id);
CREATE INDEX IF NOT EXISTS idx_logs_level ON agent_logs(level);
CREATE INDEX IF NOT EXISTS idx_metrics_execution ON execution_metrics(execution_id);
CREATE INDEX IF NOT EXISTS idx_metrics_name ON execution_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- Create triggers for updated_at
CREATE TRIGGER IF NOT EXISTS update_projects_timestamp 
AFTER UPDATE ON projects
BEGIN
    UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_project_configurations_timestamp 
AFTER UPDATE ON project_configurations
BEGIN
    UPDATE project_configurations SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_agent_configurations_timestamp 
AFTER UPDATE ON agent_configurations
BEGIN
    UPDATE agent_configurations SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_mcp_servers_timestamp 
AFTER UPDATE ON mcp_servers
BEGIN
    UPDATE mcp_servers SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_webhooks_timestamp 
AFTER UPDATE ON webhooks
BEGIN
    UPDATE webhooks SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_users_timestamp 
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;