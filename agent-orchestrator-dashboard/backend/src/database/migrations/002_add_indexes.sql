-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_executions_project ON agent_executions(project_id);
CREATE INDEX IF NOT EXISTS idx_executions_status ON agent_executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_agent ON agent_executions(agent_name);
CREATE INDEX IF NOT EXISTS idx_executions_started ON agent_executions(started_at);

CREATE INDEX IF NOT EXISTS idx_tasks_execution ON agent_tasks(execution_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON agent_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_agent ON agent_tasks(agent_name);

CREATE INDEX IF NOT EXISTS idx_logs_execution ON agent_logs(execution_id);
CREATE INDEX IF NOT EXISTS idx_logs_agent ON agent_logs(agent_name);
CREATE INDEX IF NOT EXISTS idx_logs_level ON agent_logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_created ON agent_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_metrics_execution ON execution_metrics(execution_id);
CREATE INDEX IF NOT EXISTS idx_metrics_name ON execution_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_recorded ON execution_metrics(recorded_at);

CREATE INDEX IF NOT EXISTS idx_project_configs_project ON project_configurations(project_id);
CREATE INDEX IF NOT EXISTS idx_agent_configs_project ON agent_configurations(project_id);
CREATE INDEX IF NOT EXISTS idx_agent_configs_agent ON agent_configurations(agent_name);

CREATE INDEX IF NOT EXISTS idx_webhooks_project ON webhooks(project_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_active ON webhooks(active);

CREATE INDEX IF NOT EXISTS idx_dependencies_plan ON agent_dependencies(execution_plan_id);
CREATE INDEX IF NOT EXISTS idx_dependencies_from ON agent_dependencies(from_task);
CREATE INDEX IF NOT EXISTS idx_dependencies_to ON agent_dependencies(to_task);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);