#!/bin/bash
# Test parallel orchestration with multiple Claude instances

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🎭 Parallel Orchestration Test${NC}"
echo "==============================="
echo ""

# Configuration
CLAUDE_DIR="$HOME/.claude"
TEST_PROJECT="e-commerce-mvp"
WORKSPACE_DIR="$HOME/parallel-orchestration-test"
ORCHESTRATOR_DIR="$(dirname "$0")"

# Function to create test project
create_test_project() {
    echo -e "${CYAN}Creating test project structure...${NC}"
    
    # Clean and create workspace
    rm -rf "$WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    
    # Create project structure
    mkdir -p src/{backend,frontend,database,infrastructure}
    mkdir -p docs/{api,architecture,deployment}
    mkdir -p tests/{unit,integration,e2e}
    
    # Create project brief
    cat > "PROJECT_BRIEF.md" << 'EOF'
# E-Commerce MVP Project

## Overview
Build a minimal viable e-commerce platform with:
- Product catalog
- Shopping cart
- Basic checkout
- User authentication

## Technical Requirements
- Backend: Node.js REST API
- Frontend: React SPA
- Database: PostgreSQL
- Infrastructure: Docker-ready

## Parallel Tasks
1. **Backend API** (backend-expert)
   - Design RESTful endpoints
   - Implement authentication
   - Create product CRUD operations

2. **Frontend UI** (frontend-expert)
   - Design component architecture
   - Create product listing page
   - Implement shopping cart

3. **Database Schema** (database-architect)
   - Design normalized schema
   - Create migration scripts
   - Set up indexes

4. **Infrastructure** (devops-sre-expert)
   - Create Dockerfile
   - Set up docker-compose
   - Configure CI/CD pipeline
EOF
    
    echo -e "${GREEN}✅ Project structure created${NC}"
}

# Function to create agent task files
create_agent_tasks() {
    echo -e "\n${CYAN}Creating agent-specific tasks...${NC}"
    
    # Backend task
    cat > "$WORKSPACE_DIR/src/backend/TASK.md" << 'EOF'
# Backend Development Task

## Assigned Agent: backend-expert

## Objectives
1. Create Express.js server structure
2. Implement authentication middleware
3. Design RESTful API endpoints
4. Create product model and controller

## Deliverables
- `server.js` - Main server file
- `routes/auth.js` - Authentication routes
- `routes/products.js` - Product CRUD routes
- `middleware/auth.js` - JWT middleware
- `models/Product.js` - Product model

## MCP Requirements
- filesystem: For creating files
- memory: For storing API design decisions
EOF
    
    # Frontend task
    cat > "$WORKSPACE_DIR/src/frontend/TASK.md" << 'EOF'
# Frontend Development Task

## Assigned Agent: frontend-expert

## Objectives
1. Set up React application structure
2. Create reusable components
3. Implement product listing
4. Build shopping cart functionality

## Deliverables
- `App.js` - Main application component
- `components/ProductList.js` - Product listing
- `components/ProductCard.js` - Individual product
- `components/Cart.js` - Shopping cart
- `services/api.js` - API service layer

## MCP Requirements
- filesystem: For creating files
- memory: For storing UI patterns
EOF
    
    # Database task
    cat > "$WORKSPACE_DIR/src/database/TASK.md" << 'EOF'
# Database Architecture Task

## Assigned Agent: database-architect

## Objectives
1. Design normalized database schema
2. Create migration scripts
3. Set up indexes for performance
4. Document relationships

## Deliverables
- `schema.sql` - Complete database schema
- `migrations/001_initial.sql` - Initial migration
- `indexes.sql` - Performance indexes
- `seed.sql` - Sample data

## MCP Requirements
- filesystem: For creating SQL files
- memory: For storing schema decisions
EOF
    
    # DevOps task
    cat > "$WORKSPACE_DIR/src/infrastructure/TASK.md" << 'EOF'
# Infrastructure Setup Task

## Assigned Agent: devops-sre-expert

## Objectives
1. Create Docker configuration
2. Set up docker-compose
3. Configure environment variables
4. Create CI/CD pipeline

## Deliverables
- `Dockerfile` - Application container
- `docker-compose.yml` - Full stack setup
- `.env.example` - Environment template
- `.github/workflows/ci.yml` - CI pipeline

## MCP Requirements
- filesystem: For creating config files
- memory: For storing infrastructure decisions
EOF
    
    echo -e "${GREEN}✅ Agent tasks created${NC}"
}

# Function to simulate orchestration
simulate_orchestration() {
    echo -e "\n${YELLOW}🎭 Simulating parallel orchestration...${NC}"
    
    # Create orchestration plan
    cat > "$WORKSPACE_DIR/ORCHESTRATION_PLAN.md" << 'EOF'
# Parallel Orchestration Plan

## Phase 1: Parallel Execution (All agents work simultaneously)

### Terminal 1: Backend Development
```bash
cd src/backend
claude
# Agent: backend-expert
# Task: Read TASK.md and implement backend API
```

### Terminal 2: Frontend Development
```bash
cd src/frontend
claude
# Agent: frontend-expert
# Task: Read TASK.md and implement React components
```

### Terminal 3: Database Design
```bash
cd src/database
claude
# Agent: database-architect
# Task: Read TASK.md and create schema
```

### Terminal 4: Infrastructure Setup
```bash
cd src/infrastructure
claude
# Agent: devops-sre-expert
# Task: Read TASK.md and create Docker setup
```

## Phase 2: Integration (After individual tasks complete)

1. Backend integrates with database schema
2. Frontend connects to backend API
3. DevOps containerizes the full application

## Expected Timeline
- Parallel work: 15-20 minutes
- Integration: 10 minutes
- Total: 25-30 minutes (vs 60+ minutes sequential)
EOF
    
    # Create verification script
    cat > "$WORKSPACE_DIR/verify-completion.sh" << 'EOF'
#!/bin/bash
# Verify that all agents completed their tasks

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Checking agent deliverables..."
echo "=============================="

# Check backend files
echo -e "\n${YELLOW}Backend Expert:${NC}"
backend_files=("src/backend/server.js" "src/backend/routes/auth.js" "src/backend/routes/products.js")
for file in "${backend_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
    fi
done

# Check frontend files
echo -e "\n${YELLOW}Frontend Expert:${NC}"
frontend_files=("src/frontend/App.js" "src/frontend/components/ProductList.js" "src/frontend/components/Cart.js")
for file in "${frontend_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
    fi
done

# Check database files
echo -e "\n${YELLOW}Database Architect:${NC}"
db_files=("src/database/schema.sql" "src/database/migrations/001_initial.sql")
for file in "${db_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
    fi
done

# Check infrastructure files
echo -e "\n${YELLOW}DevOps Expert:${NC}"
infra_files=("src/infrastructure/Dockerfile" "src/infrastructure/docker-compose.yml")
for file in "${infra_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file${NC}"
    fi
done

# Check for SQLite memory sharing
echo -e "\n${YELLOW}Memory Sharing:${NC}"
MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"
if [ -f "$MEMORY_DB" ]; then
    echo -e "${GREEN}✅ SQLite memory database exists${NC}"
    
    # Check for recent memories
    recent_count=$(sqlite3 "$MEMORY_DB" "SELECT COUNT(*) FROM memories WHERE datetime(created_at) > datetime('now', '-1 hour');" 2>/dev/null || echo "0")
    echo "   Recent memories created: $recent_count"
else
    echo -e "${YELLOW}⚠️  SQLite memory not found (using filesystem fallback)${NC}"
fi
EOF
    
    chmod +x "$WORKSPACE_DIR/verify-completion.sh"
    
    echo -e "${GREEN}✅ Orchestration plan created${NC}"
}

# Function to create launch scripts
create_launch_scripts() {
    echo -e "\n${CYAN}Creating launch scripts...${NC}"
    
    # Create master launch script
    cat > "$WORKSPACE_DIR/launch-all.sh" << 'EOF'
#!/bin/bash
# Launch all Claude instances in separate terminals

WORKSPACE_DIR="$(pwd)"

# Function to open terminal with command (macOS)
open_terminal() {
    local dir=$1
    local title=$2
    
    osascript -e "
    tell application \"Terminal\"
        do script \"cd '$WORKSPACE_DIR/$dir' && echo '🤖 $title' && echo 'Run: claude' && echo 'Then: Read TASK.md and complete the assigned task'\"
        activate
    end tell"
}

echo "Opening terminals for parallel execution..."

# Open terminals for each agent
open_terminal "src/backend" "Backend Expert"
sleep 1
open_terminal "src/frontend" "Frontend Expert"
sleep 1
open_terminal "src/database" "Database Architect"
sleep 1
open_terminal "src/infrastructure" "DevOps Expert"

echo ""
echo "✅ All terminals opened!"
echo ""
echo "In each terminal:"
echo "1. Run: claude"
echo "2. Ask: 'Please read TASK.md and complete the assigned task'"
echo ""
echo "To verify completion: ./verify-completion.sh"
EOF
    
    chmod +x "$WORKSPACE_DIR/launch-all.sh"
    
    echo -e "${GREEN}✅ Launch scripts created${NC}"
}

# Function to show MCP status
show_mcp_status() {
    echo -e "\n${CYAN}MCP Server Status:${NC}"
    
    local config_file="$CLAUDE_DIR/claude_desktop_config.json"
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✅ MCP configuration found${NC}"
        
        # Check specific servers
        local servers=("filesystem" "memory" "git" "web")
        for server in "${servers[@]}"; do
            if grep -q "\"$server\"" "$config_file" 2>/dev/null; then
                echo -e "   ${GREEN}✅ $server${NC}"
            else
                echo -e "   ${YELLOW}⚠️  $server (not configured)${NC}"
            fi
        done
    else
        echo -e "${RED}❌ MCP configuration not found${NC}"
        echo "Agents will have limited functionality"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Setting up parallel orchestration test...${NC}"
    
    # Create test project
    create_test_project
    
    # Create agent tasks
    create_agent_tasks
    
    # Set up orchestration
    simulate_orchestration
    
    # Create launch scripts
    create_launch_scripts
    
    # Show MCP status
    show_mcp_status
    
    # Show instructions
    echo -e "\n${BLUE}📋 Test Instructions:${NC}"
    echo "==================="
    echo ""
    echo "1. Navigate to test directory:"
    echo "   cd $WORKSPACE_DIR"
    echo ""
    echo "2. Launch all instances (macOS):"
    echo "   ./launch-all.sh"
    echo ""
    echo "3. In each Claude terminal, type:"
    echo "   'Please read TASK.md and complete the assigned task'"
    echo ""
    echo "4. Watch agents work in parallel!"
    echo ""
    echo "5. Verify completion:"
    echo "   ./verify-completion.sh"
    echo ""
    echo -e "${PURPLE}🎯 Expected Result:${NC}"
    echo "All 4 agents should work simultaneously, creating their"
    echo "deliverables in parallel, potentially sharing insights"
    echo "through the SQLite memory system."
    echo ""
    echo -e "${GREEN}✅ Test setup complete!${NC}"
}

# Run main
main

echo -e "\n${BLUE}Workspace: $WORKSPACE_DIR${NC}"