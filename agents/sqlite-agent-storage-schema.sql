-- Comprehensive SQLite Schema for Agent Storage
-- Maintains dual storage: SQLite for functionality + files for visibility

-- Agent registry (mirrors agent-registry.json)
CREATE TABLE IF NOT EXISTS agent_registry (
    agent_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    expertise_areas TEXT, -- JSON array
    collaboration_patterns TEXT, -- JSON object
    tool_requirements TEXT, -- JSON array
    mcp_requirements TEXT, -- JSON array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent definitions (content of .md files)
CREATE TABLE IF NOT EXISTS agent_definitions (
    agent_id TEXT PRIMARY KEY,
    frontmatter TEXT, -- YAML frontmatter
    prompt_content TEXT, -- Main prompt content
    version INTEGER DEFAULT 1,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Agent tasks (replaces file-based task tracking)
CREATE TABLE IF NOT EXISTS agent_tasks (
    task_id TEXT PRIMARY KEY, -- {AGENT_PREFIX}-{YYYYMMDD}-{SEQUENCE}
    agent_id TEXT NOT NULL,
    task_date DATE NOT NULL,
    sequence_number INTEGER NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, in_progress, completed, failed
    priority TEXT DEFAULT 'medium', -- low, medium, high, critical
    title TEXT,
    description TEXT,
    deliverables TEXT, -- JSON array
    dependencies TEXT, -- JSON array of task_ids
    parent_task_id TEXT, -- For subtasks
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (parent_task_id) REFERENCES agent_tasks(task_id)
);

-- Agent workspace content (mirrors Agent-{Name}.md files)
CREATE TABLE IF NOT EXISTS agent_workspaces (
    workspace_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    session_id TEXT,
    content_type TEXT, -- 'status', 'plan', 'progress', 'result', 'note'
    content TEXT,
    metadata TEXT, -- JSON object for additional data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Agent outputs (structured output following schema)
CREATE TABLE IF NOT EXISTS agent_outputs (
    output_id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    status TEXT NOT NULL, -- completed, in-progress, failed
    deliverables TEXT, -- JSON array
    insights TEXT, -- JSON array
    metrics TEXT, -- JSON object
    suggested_agents TEXT, -- JSON array
    next_steps TEXT, -- JSON array
    error_details TEXT, -- For failed tasks
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES agent_tasks(task_id),
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
);

-- Tool usage tracking
CREATE TABLE IF NOT EXISTS tool_usage (
    usage_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    task_id TEXT,
    tool_name TEXT NOT NULL,
    tool_type TEXT, -- 'core', 'mcp', 'agent'
    parameters TEXT, -- JSON object
    result_summary TEXT,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (task_id) REFERENCES agent_tasks(task_id)
);

-- Agent collaboration events
CREATE TABLE IF NOT EXISTS collaboration_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    event_type TEXT, -- 'task_handoff', 'data_share', 'request', 'response'
    task_id TEXT,
    payload TEXT, -- JSON object
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_agent) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (to_agent) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (task_id) REFERENCES agent_tasks(task_id)
);

-- Agent performance metrics
CREATE TABLE IF NOT EXISTS agent_performance (
    metric_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    task_id TEXT,
    metric_type TEXT, -- 'task_completion_time', 'success_rate', 'tool_usage', etc.
    metric_value REAL,
    metric_metadata TEXT, -- JSON object
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (task_id) REFERENCES agent_tasks(task_id)
);

-- MCP server availability tracking
CREATE TABLE IF NOT EXISTS mcp_availability (
    server_name TEXT PRIMARY KEY,
    is_available BOOLEAN DEFAULT FALSE,
    executable_path TEXT,
    configuration TEXT, -- JSON object
    last_checked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT
);

-- Slash commands registry
CREATE TABLE IF NOT EXISTS slash_commands (
    command_name TEXT PRIMARY KEY,
    description TEXT,
    file_path TEXT,
    is_agent_accessible BOOLEAN DEFAULT FALSE, -- Can agents use this command?
    usage_example TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session tracking
CREATE TABLE IF NOT EXISTS orchestration_sessions (
    session_id TEXT PRIMARY KEY,
    project_name TEXT,
    project_level INTEGER DEFAULT 3,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status TEXT DEFAULT 'active', -- active, completed, failed
    participating_agents TEXT, -- JSON array
    project_metadata TEXT -- JSON object
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_agent_date ON agent_tasks(agent_id, task_date);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON agent_tasks(status);
CREATE INDEX IF NOT EXISTS idx_outputs_task ON agent_outputs(task_id);
CREATE INDEX IF NOT EXISTS idx_tool_usage_agent ON tool_usage(agent_id, created_at);
CREATE INDEX IF NOT EXISTS idx_workspaces_agent ON agent_workspaces(agent_id, created_at);
CREATE INDEX IF NOT EXISTS idx_collaboration_agents ON collaboration_events(from_agent, to_agent);

-- Views for common queries

-- Active tasks by agent
CREATE VIEW IF NOT EXISTS active_tasks_by_agent AS
SELECT 
    a.name as agent_name,
    t.task_id,
    t.title,
    t.status,
    t.priority,
    t.created_at
FROM agent_tasks t
JOIN agent_registry a ON t.agent_id = a.agent_id
WHERE t.status IN ('pending', 'in_progress')
ORDER BY t.priority DESC, t.created_at ASC;

-- Agent collaboration summary
CREATE VIEW IF NOT EXISTS collaboration_summary AS
SELECT 
    from_agent,
    to_agent,
    COUNT(*) as interaction_count,
    MAX(created_at) as last_interaction
FROM collaboration_events
GROUP BY from_agent, to_agent;

-- Tool usage statistics
CREATE VIEW IF NOT EXISTS tool_usage_stats AS
SELECT 
    agent_id,
    tool_name,
    tool_type,
    COUNT(*) as usage_count,
    AVG(CASE WHEN success THEN 1 ELSE 0 END) as success_rate,
    AVG(execution_time_ms) as avg_execution_time
FROM tool_usage
GROUP BY agent_id, tool_name, tool_type;

-- Triggers for automatic timestamps
CREATE TRIGGER IF NOT EXISTS update_agent_registry_timestamp 
AFTER UPDATE ON agent_registry
BEGIN
    UPDATE agent_registry SET updated_at = CURRENT_TIMESTAMP WHERE agent_id = NEW.agent_id;
END;

-- Trigger to sync workspace content to files
CREATE TRIGGER IF NOT EXISTS sync_workspace_to_file
AFTER INSERT ON agent_workspaces
BEGIN
    -- This trigger would call a function to write to Agent-{Name}.md
    -- Implementation depends on the runtime environment
    SELECT 'SYNC_WORKSPACE:' || NEW.agent_id || ':' || NEW.workspace_id;
END;