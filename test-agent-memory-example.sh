#!/bin/bash
# Practical example of agents using SQLite memory

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

echo -e "${BLUE}🤖 Agent Memory Collaboration Example${NC}"
echo "====================================="
echo ""

# Initialize database
echo -e "${YELLOW}Initializing collaboration database...${NC}"
sqlite3 "$MEMORY_DB" << 'EOF'
-- Create memories table if not exists
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    memory_type TEXT NOT NULL,
    content TEXT NOT NULL,
    importance INTEGER DEFAULT 5,
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    access_count INTEGER DEFAULT 0
);

-- Create projects table for context
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_by TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear previous test data
DELETE FROM memories WHERE agent_id LIKE 'test-%';
EOF

# Simulate a project kickoff
echo -e "\n${PURPLE}📋 Project: E-Commerce Platform Development${NC}"
echo "==========================================="

# Orchestration agent creates project context
echo -e "\n${BLUE}[orchestration-agent]${NC} Starting project analysis..."
sqlite3 "$MEMORY_DB" << 'EOF'
INSERT INTO projects (name, description, created_by)
VALUES ('E-Commerce Platform', 'Modern SaaS e-commerce with multi-tenant support', 'orchestration-agent');

INSERT INTO memories (agent_id, memory_type, content, importance, metadata)
VALUES 
    ('orchestration-agent', 'project_requirements', 'Multi-tenant SaaS architecture required', 10, '{"project": "e-commerce", "phase": "planning"}'),
    ('orchestration-agent', 'technical_decisions', 'Microservices architecture chosen for scalability', 9, '{"project": "e-commerce", "shared": true}'),
    ('orchestration-agent', 'team_assignments', 'Backend: Node.js/Express, Frontend: React, Database: PostgreSQL', 8, '{"project": "e-commerce", "shared": true}');
EOF
echo -e "${GREEN}✅ Project context established${NC}"

# Business analyst adds market research
echo -e "\n${BLUE}[business-analyst]${NC} Conducting market analysis..."
sqlite3 "$MEMORY_DB" << 'EOF'
INSERT INTO memories (agent_id, memory_type, content, importance, metadata)
VALUES 
    ('business-analyst', 'market_research', 'Target market: Small to medium businesses needing quick setup', 9, '{"project": "e-commerce", "shared": true}'),
    ('business-analyst', 'competitor_analysis', 'Main competitors: Shopify, WooCommerce. Our advantage: Better API', 8, '{"project": "e-commerce", "shared": true}'),
    ('business-analyst', 'pricing_insight', 'Freemium model recommended: Free up to 100 products', 9, '{"project": "e-commerce", "shared": true}');
EOF
echo -e "${GREEN}✅ Market analysis completed${NC}"

# Database architect designs schema
echo -e "\n${BLUE}[database-architect]${NC} Designing database schema..."
sqlite3 "$MEMORY_DB" << 'EOF'
INSERT INTO memories (agent_id, memory_type, content, importance, metadata)
VALUES 
    ('database-architect', 'schema_decision', 'Using PostgreSQL with tenant isolation via schemas', 10, '{"project": "e-commerce", "shared": true}'),
    ('database-architect', 'table_structure', 'Core tables: tenants, users, products, orders, payments', 9, '{"project": "e-commerce", "shared": true}'),
    ('database-architect', 'performance_note', 'Implement Redis caching for product catalog', 8, '{"project": "e-commerce", "shared": true}');
EOF
echo -e "${GREEN}✅ Database schema designed${NC}"

# Backend expert retrieves shared knowledge
echo -e "\n${BLUE}[backend-expert]${NC} Reviewing project knowledge..."
echo -e "${YELLOW}Accessing shared memories...${NC}"

# Query shared memories for backend expert
sqlite3 "$MEMORY_DB" << 'EOF'
-- Update access count for retrieved memories
UPDATE memories 
SET access_count = access_count + 1, 
    accessed_at = CURRENT_TIMESTAMP
WHERE json_extract(metadata, '$.shared') = 1;

-- Backend expert adds API design based on shared knowledge
INSERT INTO memories (agent_id, memory_type, content, importance, metadata)
VALUES 
    ('backend-expert', 'api_design', 'RESTful API with /api/v1/{tenant}/ structure', 9, '{"project": "e-commerce", "shared": true}'),
    ('backend-expert', 'authentication', 'JWT with tenant scope validation', 9, '{"project": "e-commerce", "shared": true}'),
    ('backend-expert', 'integration', 'Stripe for payments, SendGrid for emails', 8, '{"project": "e-commerce", "shared": true}');
EOF

# Show what backend expert learned
echo -e "\n${PURPLE}📚 Knowledge Retrieved by Backend Expert:${NC}"
sqlite3 -column -header "$MEMORY_DB" << 'EOF'
SELECT 
    agent_id as "From Agent",
    substr(content, 1, 50) || '...' as "Memory Content",
    importance as "Importance"
FROM memories 
WHERE json_extract(metadata, '$.shared') = 1
  AND agent_id != 'backend-expert'
ORDER BY importance DESC
LIMIT 5;
EOF

# Frontend expert uses backend's API design
echo -e "\n${BLUE}[frontend-expert]${NC} Planning UI based on API design..."
BACKEND_API=$(sqlite3 "$MEMORY_DB" "SELECT content FROM memories WHERE agent_id='backend-expert' AND memory_type='api_design' LIMIT 1;")
echo -e "${YELLOW}Found API structure: $BACKEND_API${NC}"

sqlite3 "$MEMORY_DB" << 'EOF'
INSERT INTO memories (agent_id, memory_type, content, importance, metadata)
VALUES 
    ('frontend-expert', 'ui_architecture', 'React with Redux for state, Axios for API calls', 8, '{"project": "e-commerce", "shared": true}'),
    ('frontend-expert', 'routing', 'Tenant-aware routing: /:tenant/products, /:tenant/orders', 8, '{"project": "e-commerce", "shared": true}');
EOF
echo -e "${GREEN}✅ Frontend architecture planned${NC}"

# Show collaboration summary
echo -e "\n${BLUE}📊 Collaboration Summary:${NC}"
echo "========================="

# Count memories by agent
echo -e "\n${YELLOW}Memories Created by Each Agent:${NC}"
sqlite3 -column -header "$MEMORY_DB" << 'EOF'
SELECT 
    agent_id as "Agent",
    COUNT(*) as "Memories",
    AVG(importance) as "Avg Importance",
    SUM(access_count) as "Total Accesses"
FROM memories 
WHERE agent_id NOT LIKE 'test-%'
GROUP BY agent_id
ORDER BY COUNT(*) DESC;
EOF

# Show most important shared memories
echo -e "\n${YELLOW}Most Important Shared Memories:${NC}"
sqlite3 -column -header "$MEMORY_DB" << 'EOF'
SELECT 
    agent_id as "Agent",
    memory_type as "Type",
    substr(content, 1, 40) || '...' as "Content",
    importance as "Imp"
FROM memories 
WHERE json_extract(metadata, '$.shared') = 1
  AND importance >= 9
ORDER BY importance DESC
LIMIT 5;
EOF

# Show cross-references
echo -e "\n${YELLOW}Knowledge Flow (Who accessed what):${NC}"
sqlite3 -column -header "$MEMORY_DB" << 'EOF'
SELECT 
    agent_id as "Memory Owner",
    memory_type as "Type",
    access_count as "Access Count",
    datetime(accessed_at) as "Last Accessed"
FROM memories 
WHERE access_count > 0
ORDER BY access_count DESC
LIMIT 5;
EOF

echo -e "\n${GREEN}🎉 Agent collaboration example completed!${NC}"
echo ""
echo -e "${BLUE}Database location: $MEMORY_DB${NC}"
echo -e "To explore further: sqlite3 $MEMORY_DB"
echo ""

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"content": "Test SQLite memory system installation", "status": "completed", "priority": "high", "id": "1"}, {"content": "Verify memory adapter agent functionality", "status": "completed", "priority": "high", "id": "2"}, {"content": "Test cross-agent memory sharing", "status": "completed", "priority": "medium", "id": "3"}, {"content": "Verify fallback to filesystem", "status": "completed", "priority": "medium", "id": "4"}]