-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'inactive',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    config JSON
);

-- Agent executions
CREATE TABLE IF NOT EXISTS agent_executions (
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
CREATE TABLE IF NOT EXISTS execution_plans (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    plan JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent tasks
CREATE TABLE IF NOT EXISTS agent_tasks (
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
CREATE TABLE IF NOT EXISTS agent_logs (
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
CREATE TABLE IF NOT EXISTS project_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    config_type TEXT,
    config_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent configurations
CREATE TABLE IF NOT EXISTS agent_configurations (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    agent_name TEXT,
    config JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Execution metrics
CREATE TABLE IF NOT EXISTS execution_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execution_id TEXT,
    metric_name TEXT,
    metric_value REAL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (execution_id) REFERENCES agent_executions(id)
);

-- MCP servers
CREATE TABLE IF NOT EXISTS mcp_servers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    status TEXT,
    config JSON,
    last_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Agent dependencies
CREATE TABLE IF NOT EXISTS agent_dependencies (
    id TEXT PRIMARY KEY,
    execution_plan_id TEXT,
    from_task TEXT,
    to_task TEXT,
    dependency_type TEXT,
    FOREIGN KEY (execution_plan_id) REFERENCES execution_plans(id)
);

-- Users (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'user',
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
    FOREIGN KEY (user_id) REFERENCES users(id)
);