-- Enhanced Coordination Schema for Agent System
-- Enables autonomous agent coordination and capability expansion

-- Agent coordination queue for task delegation
CREATE TABLE IF NOT EXISTS agent_coordination_queue (
    coordination_id TEXT PRIMARY KEY,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    task_type TEXT NOT NULL, -- 'delegation', 'collaboration', 'review', 'handoff'
    task_data TEXT NOT NULL, -- JSON with full task details
    priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    status TEXT DEFAULT 'pending', -- 'pending', 'claimed', 'in_progress', 'completed', 'failed'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    claimed_at TIMESTAMP,
    completed_at TIMESTAMP,
    result TEXT, -- JSON result data
    error_details TEXT,
    FOREIGN KEY (from_agent) REFERENCES agent_registry(agent_id),
    FOREIGN KEY (to_agent) REFERENCES agent_registry(agent_id)
);

-- Missing capabilities tracking
CREATE TABLE IF NOT EXISTS missing_capabilities (
    capability_id INTEGER PRIMARY KEY AUTOINCREMENT,
    capability_type TEXT NOT NULL, -- 'tool', 'mcp', 'agent', 'expertise', 'library'
    capability_name TEXT NOT NULL,
    requested_by_agent TEXT NOT NULL,
    task_context TEXT, -- JSON context when capability was needed
    impact_level TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'blocking'
    frequency INTEGER DEFAULT 1, -- Times requested
    first_requested TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_requested TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolution_status TEXT DEFAULT 'pending', -- 'pending', 'investigating', 'resolved', 'wont_fix'
    resolution_method TEXT, -- How it was resolved
    resolution_details TEXT, -- JSON details
    resolved_at TIMESTAMP,
    FOREIGN KEY (requested_by_agent) REFERENCES agent_registry(agent_id)
);

-- Capability resolution proposals
CREATE TABLE IF NOT EXISTS capability_proposals (
    proposal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    capability_id INTEGER NOT NULL,
    proposal_type TEXT NOT NULL, -- 'install_tool', 'create_agent', 'install_mcp', 'find_alternative'
    proposal_details TEXT NOT NULL, -- JSON with specific steps
    proposed_by TEXT NOT NULL, -- Agent or system that proposed
    confidence_score REAL NOT NULL, -- 0.0 to 1.0
    safety_score REAL, -- 0.0 to 1.0
    estimated_duration INTEGER, -- Estimated minutes to implement
    dependencies TEXT, -- JSON array of dependencies
    status TEXT DEFAULT 'proposed', -- 'proposed', 'approved', 'rejected', 'implemented', 'failed'
    approval_required BOOLEAN DEFAULT TRUE,
    auto_approve_after TIMESTAMP, -- Auto-approve if high confidence
    implementation_result TEXT, -- JSON result if implemented
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    implemented_at TIMESTAMP,
    FOREIGN KEY (capability_id) REFERENCES missing_capabilities(capability_id)
);

-- Pending agent definitions
CREATE TABLE IF NOT EXISTS pending_agents (
    agent_id TEXT PRIMARY KEY,
    proposed_by TEXT NOT NULL,
    agent_name TEXT NOT NULL,
    description TEXT,
    expertise_areas TEXT, -- JSON array
    based_on_template TEXT, -- Template agent ID if any
    definition TEXT NOT NULL, -- JSON full agent definition
    justification TEXT, -- Why this agent is needed
    expected_usage TEXT, -- JSON expected use cases
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'created'
    approval_score REAL, -- Calculated approval score
    similar_agents TEXT, -- JSON array of similar existing agents
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    created_agent_at TIMESTAMP,
    FOREIGN KEY (proposed_by) REFERENCES agent_registry(agent_id)
);

-- Tool installation tracking
CREATE TABLE IF NOT EXISTS tool_installations (
    install_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tool_name TEXT NOT NULL,
    tool_type TEXT, -- 'npm', 'pip', 'binary', 'script'
    requested_by TEXT NOT NULL,
    install_command TEXT,
    verification_command TEXT,
    install_location TEXT,
    version TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'installing', 'verifying', 'installed', 'failed'
    error_message TEXT,
    safety_checks TEXT, -- JSON array of safety check results
    installed_at TIMESTAMP,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (requested_by) REFERENCES agent_registry(agent_id)
);

-- MCP server installation tracking
CREATE TABLE IF NOT EXISTS mcp_installations (
    install_id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_name TEXT NOT NULL,
    repository_url TEXT,
    npm_package TEXT,
    requested_by TEXT NOT NULL,
    installation_steps TEXT, -- JSON array of steps
    configuration TEXT, -- JSON config to add
    requirements TEXT, -- JSON requirements
    status TEXT DEFAULT 'pending',
    current_step INTEGER DEFAULT 0,
    total_steps INTEGER,
    error_details TEXT,
    installed_at TIMESTAMP,
    configured_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (requested_by) REFERENCES agent_registry(agent_id)
);

-- Collaboration requests between agents
CREATE TABLE IF NOT EXISTS collaboration_requests (
    request_id TEXT PRIMARY KEY,
    requester TEXT NOT NULL,
    required_expertise TEXT NOT NULL, -- JSON array of required skills
    task_context TEXT NOT NULL, -- JSON full context
    urgency TEXT DEFAULT 'normal', -- 'low', 'normal', 'high', 'critical'
    min_agents INTEGER DEFAULT 1,
    max_agents INTEGER DEFAULT 3,
    status TEXT DEFAULT 'open', -- 'open', 'assigned', 'in_progress', 'completed', 'cancelled'
    suitable_agents TEXT, -- JSON array of agent IDs
    assigned_agents TEXT, -- JSON array of assigned agent IDs
    collaboration_result TEXT, -- JSON result
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    completed_at TIMESTAMP,
    FOREIGN KEY (requester) REFERENCES agent_registry(agent_id)
);

-- Human approval queue
CREATE TABLE IF NOT EXISTS approval_queue (
    approval_id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT NOT NULL, -- 'install_tool', 'create_agent', 'install_mcp', 'execute_command'
    action_details TEXT NOT NULL, -- JSON full details
    requested_by TEXT NOT NULL,
    safety_score REAL, -- 0.0 to 1.0
    risk_assessment TEXT, -- JSON risk details
    requires_approval BOOLEAN DEFAULT TRUE,
    auto_approve_threshold REAL DEFAULT 0.9,
    auto_approve_after TIMESTAMP,
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'auto_approved', 'expired'
    approved_by TEXT, -- User or 'system' for auto-approval
    approval_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    FOREIGN KEY (requested_by) REFERENCES agent_registry(agent_id)
);

-- Agent capability discoveries
CREATE TABLE IF NOT EXISTS capability_discoveries (
    discovery_id INTEGER PRIMARY KEY AUTOINCREMENT,
    discovering_agent TEXT NOT NULL,
    discovery_type TEXT, -- 'new_tool', 'new_pattern', 'optimization', 'workaround'
    discovery_name TEXT,
    discovery_details TEXT, -- JSON full details
    applicable_to TEXT, -- JSON array of scenarios
    effectiveness_score REAL, -- 0.0 to 1.0
    shared_with_agents TEXT DEFAULT '[]', -- JSON array
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (discovering_agent) REFERENCES agent_registry(agent_id)
);

-- Resource allocation for parallel work
CREATE TABLE IF NOT EXISTS resource_allocation (
    allocation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    resource_type TEXT NOT NULL, -- 'compute', 'memory', 'mcp_server', 'tool_instance'
    resource_identifier TEXT NOT NULL,
    allocated_to TEXT NOT NULL,
    allocation_purpose TEXT,
    allocated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP,
    max_duration INTEGER, -- Maximum allocation time in seconds
    FOREIGN KEY (allocated_to) REFERENCES agent_registry(agent_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_coordination_queue_status 
    ON agent_coordination_queue(status, priority, created_at);
CREATE INDEX IF NOT EXISTS idx_coordination_queue_agents 
    ON agent_coordination_queue(to_agent, status);
CREATE INDEX IF NOT EXISTS idx_missing_capabilities_type 
    ON missing_capabilities(capability_type, resolution_status);
CREATE INDEX IF NOT EXISTS idx_proposals_status 
    ON capability_proposals(status, confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_collaboration_status 
    ON collaboration_requests(status, urgency);
CREATE INDEX IF NOT EXISTS idx_approval_queue_pending 
    ON approval_queue(status, auto_approve_after);

-- Views for coordination insights

-- Active coordination tasks by agent
CREATE VIEW IF NOT EXISTS active_coordinations AS
SELECT 
    to_agent,
    COUNT(*) as pending_tasks,
    MAX(CASE WHEN priority = 'critical' THEN 1 ELSE 0 END) as has_critical,
    MIN(created_at) as oldest_task
FROM agent_coordination_queue
WHERE status IN ('pending', 'claimed')
GROUP BY to_agent;

-- Capability gap analysis
CREATE VIEW IF NOT EXISTS capability_gaps AS
SELECT 
    capability_type,
    capability_name,
    COUNT(DISTINCT requested_by_agent) as unique_requesters,
    SUM(frequency) as total_requests,
    MAX(last_requested) as most_recent,
    resolution_status
FROM missing_capabilities
WHERE resolution_status != 'resolved'
GROUP BY capability_type, capability_name
ORDER BY total_requests DESC;

-- Agent collaboration network
CREATE VIEW IF NOT EXISTS collaboration_network AS
SELECT 
    c.from_agent,
    c.to_agent,
    COUNT(*) as collaboration_count,
    AVG(CASE WHEN c.status = 'completed' THEN 1 ELSE 0 END) as success_rate,
    AVG(julianday(c.completed_at) - julianday(c.created_at)) * 24 as avg_hours
FROM agent_coordination_queue c
WHERE c.task_type IN ('collaboration', 'delegation')
GROUP BY c.from_agent, c.to_agent;

-- Pending approvals summary
CREATE VIEW IF NOT EXISTS pending_approvals_summary AS
SELECT 
    action_type,
    COUNT(*) as pending_count,
    AVG(safety_score) as avg_safety_score,
    MIN(created_at) as oldest_request
FROM approval_queue
WHERE status = 'pending'
GROUP BY action_type;

-- Triggers for automation

-- Auto-approve high confidence proposals
CREATE TRIGGER IF NOT EXISTS auto_approve_proposals
AFTER UPDATE ON capability_proposals
WHEN NEW.confidence_score >= 0.9 
    AND NEW.safety_score >= 0.8 
    AND NEW.status = 'proposed'
    AND datetime('now') >= NEW.auto_approve_after
BEGIN
    UPDATE capability_proposals 
    SET status = 'approved', reviewed_at = CURRENT_TIMESTAMP
    WHERE proposal_id = NEW.proposal_id;
END;

-- Update missing capability frequency
CREATE TRIGGER IF NOT EXISTS update_capability_frequency
BEFORE INSERT ON missing_capabilities
BEGIN
    UPDATE missing_capabilities 
    SET frequency = frequency + 1,
        last_requested = CURRENT_TIMESTAMP
    WHERE capability_type = NEW.capability_type 
        AND capability_name = NEW.capability_name
        AND requested_by_agent = NEW.requested_by_agent;
    
    SELECT RAISE(IGNORE) 
    WHERE EXISTS (
        SELECT 1 FROM missing_capabilities 
        WHERE capability_type = NEW.capability_type 
            AND capability_name = NEW.capability_name
            AND requested_by_agent = NEW.requested_by_agent
    );
END;

-- Notify agents of new coordination tasks
CREATE TRIGGER IF NOT EXISTS notify_coordination_task
AFTER INSERT ON agent_coordination_queue
BEGIN
    INSERT INTO agent_notifications (
        agent_id, notification_type, notification_data, created_at
    ) VALUES (
        NEW.to_agent, 
        'new_coordination_task',
        json_object('coordination_id', NEW.coordination_id, 
                   'from_agent', NEW.from_agent,
                   'priority', NEW.priority),
        CURRENT_TIMESTAMP
    );
END;