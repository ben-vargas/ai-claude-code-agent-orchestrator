#!/bin/bash
# Real-time agent monitoring dashboard

MEMORY_DB="$HOME/.claude/agent-memory/agent-collaboration.db"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Function to format duration
format_duration() {
    local ms=$1
    if [ $ms -lt 1000 ]; then
        echo "${ms}ms"
    elif [ $ms -lt 60000 ]; then
        echo "$((ms/1000))s"
    else
        echo "$((ms/60000))m"
    fi
}

# Function to show progress bar
progress_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%%" $percent
}

# Main dashboard loop
while true; do
    clear
    
    # Header
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║          🤖 Claude Code Agent Activity Dashboard 🤖            ║${NC}"
    echo -e "${BOLD}${BLUE}╟────────────────────────────────────────────────────────────────╢${NC}"
    echo -e "${BOLD}${BLUE}║${NC} $(date '+%Y-%m-%d %H:%M:%S') ${BLUE}│${NC} Press Ctrl+C to exit              ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Active Agents Summary
    echo -e "${CYAN}📊 Active Agent Sessions${NC}"
    echo "────────────────────────"
    
    ACTIVE_AGENTS=$(sqlite3 "$MEMORY_DB" "
        SELECT COUNT(DISTINCT agent_id) 
        FROM hook_agent_sessions 
        WHERE end_time IS NULL
    " 2>/dev/null || echo "0")
    
    TOTAL_ACTIVITY=$(sqlite3 "$MEMORY_DB" "
        SELECT COUNT(*) 
        FROM hook_tool_usage 
        WHERE datetime(hook_timestamp) > datetime('now', '-5 minutes')
    " 2>/dev/null || echo "0")
    
    echo -e "Active Agents: ${GREEN}$ACTIVE_AGENTS${NC} | Recent Activity: ${YELLOW}$TOTAL_ACTIVITY${NC} operations"
    echo ""
    
    # Per-Agent Statistics
    echo -e "${CYAN}🎯 Agent Performance (Last Hour)${NC}"
    echo "─────────────────────────────────"
    
    sqlite3 -separator ' │ ' "$MEMORY_DB" << 'EOF' 2>/dev/null | while IFS='│' read -r agent tools success_rate avg_duration errors; do
        # Trim whitespace
        agent=$(echo "$agent" | xargs)
        tools=$(echo "$tools" | xargs)
        success_rate=$(echo "$success_rate" | xargs)
        avg_duration=$(echo "$avg_duration" | xargs)
        errors=$(echo "$errors" | xargs)
        
        # Color code success rate
        if [ "${success_rate%.*}" -ge 90 ]; then
            rate_color=$GREEN
        elif [ "${success_rate%.*}" -ge 70 ]; then
            rate_color=$YELLOW
        else
            rate_color=$RED
        fi
        
        # Format output
        printf "%-20s Tools: %-4s Success: ${rate_color}%5s%%${NC} Avg: %-6s Errors: " \
            "$agent" "$tools" "$success_rate" "$(format_duration $avg_duration)"
        
        if [ "$errors" -eq 0 ]; then
            echo -e "${GREEN}$errors${NC}"
        else
            echo -e "${RED}$errors${NC}"
        fi
    done << 'SQL'
SELECT 
    agent_id,
    COUNT(DISTINCT event_id) as tool_uses,
    ROUND(AVG(CASE WHEN success = 1 THEN 100.0 ELSE 0.0 END), 1) as success_rate,
    CAST(AVG(execution_duration_ms) AS INTEGER) as avg_duration,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as errors
FROM hook_tool_usage
WHERE datetime(hook_timestamp) > datetime('now', '-1 hour')
GROUP BY agent_id
ORDER BY tool_uses DESC
LIMIT 10;
SQL
    
    echo ""
    
    # Current Tasks Progress
    echo -e "${CYAN}📈 Task Progress${NC}"
    echo "───────────────"
    
    sqlite3 -separator ' │ ' "$MEMORY_DB" << 'EOF' 2>/dev/null | while IFS='│' read -r agent task_id progress event_type; do
        agent=$(echo "$agent" | xargs)
        task_id=$(echo "$task_id" | xargs)
        progress=$(echo "$progress" | xargs)
        event_type=$(echo "$event_type" | xargs)
        
        printf "%-15s %-15s " "$agent" "$task_id"
        progress_bar $progress
        
        # Status indicator
        case "$event_type" in
            "task_complete") echo -e " ${GREEN}✓${NC}" ;;
            "task_blocked") echo -e " ${RED}⚠${NC}" ;;
            "milestone") echo -e " ${YELLOW}◆${NC}" ;;
            *) echo "" ;;
        esac
    done << 'SQL'
SELECT 
    p1.agent_id,
    p1.task_id,
    p1.progress_percentage,
    p1.event_type
FROM hook_progress_events p1
INNER JOIN (
    SELECT agent_id, task_id, MAX(timestamp) as max_time
    FROM hook_progress_events
    WHERE task_id IS NOT NULL AND task_id != ''
    GROUP BY agent_id, task_id
) p2 ON p1.agent_id = p2.agent_id 
    AND p1.task_id = p2.task_id 
    AND p1.timestamp = p2.max_time
ORDER BY p1.timestamp DESC
LIMIT 8;
SQL
    
    echo ""
    
    # Recent Tool Activity
    echo -e "${CYAN}🛠️  Recent Tool Activity${NC}"
    echo "──────────────────────"
    
    sqlite3 -separator ' │ ' "$MEMORY_DB" << 'EOF' 2>/dev/null | while IFS='│' read -r time agent tool success duration; do
        time=$(echo "$time" | xargs)
        agent=$(echo "$agent" | xargs)
        tool=$(echo "$tool" | xargs)
        success=$(echo "$success" | xargs)
        duration=$(echo "$duration" | xargs)
        
        # Format time to show only HH:MM:SS
        time=$(echo "$time" | cut -d' ' -f2)
        
        # Success indicator
        if [ "$success" = "1" ]; then
            status="${GREEN}✓${NC}"
        else
            status="${RED}✗${NC}"
        fi
        
        printf "%s %s %-15s %-20s %6s\n" \
            "$time" "$status" "$agent" "$tool" "$(format_duration $duration)"
    done << 'SQL'
SELECT 
    datetime(hook_timestamp, 'localtime') as time,
    agent_id,
    tool_name,
    success,
    execution_duration_ms
FROM hook_tool_usage
ORDER BY hook_timestamp DESC
LIMIT 10;
SQL
    
    echo ""
    
    # Error Summary
    echo -e "${CYAN}❌ Recent Errors & Recovery${NC}"
    echo "─────────────────────────"
    
    ERROR_COUNT=$(sqlite3 "$MEMORY_DB" "
        SELECT COUNT(*) 
        FROM hook_error_events 
        WHERE datetime(timestamp) > datetime('now', '-10 minutes')
    " 2>/dev/null || echo "0")
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        sqlite3 -separator ' │ ' "$MEMORY_DB" << 'EOF' 2>/dev/null | while IFS='│' read -r agent error_type recovery impact; do
            agent=$(echo "$agent" | xargs)
            error_type=$(echo "$error_type" | xargs)
            recovery=$(echo "$recovery" | xargs)
            impact=$(echo "$impact" | xargs)
            
            # Impact color
            case "$impact" in
                "critical") impact_color=$RED ;;
                "high") impact_color=$YELLOW ;;
                *) impact_color=$NC ;;
            esac
            
            # Recovery status
            if [ "$recovery" = "1" ]; then
                recovery_status="${GREEN}[Attempted]${NC}"
            else
                recovery_status=""
            fi
            
            printf "%-15s ${impact_color}%-8s${NC} %-20s %s\n" \
                "$agent" "$impact" "$error_type" "$recovery_status"
        done << 'SQL'
SELECT 
    agent_id,
    error_type,
    recovery_attempted,
    impact_level
FROM hook_error_events
WHERE datetime(timestamp) > datetime('now', '-10 minutes')
ORDER BY timestamp DESC
LIMIT 5;
SQL
    else
        echo -e "${GREEN}No recent errors ✓${NC}"
    fi
    
    echo ""
    
    # Missing Capabilities
    echo -e "${CYAN}🔍 Missing Capabilities${NC}"
    echo "─────────────────────"
    
    MISSING_COUNT=$(sqlite3 "$MEMORY_DB" "
        SELECT COUNT(*) 
        FROM missing_capabilities 
        WHERE resolution_status = 'pending'
    " 2>/dev/null || echo "0")
    
    if [ "$MISSING_COUNT" -gt 0 ]; then
        sqlite3 -separator ' │ ' "$MEMORY_DB" << 'EOF' 2>/dev/null | head -5 | while IFS='│' read -r type name frequency agents; do
            type=$(echo "$type" | xargs)
            name=$(echo "$name" | xargs)
            frequency=$(echo "$frequency" | xargs)
            agents=$(echo "$agents" | xargs)
            
            printf "%-10s %-20s Requested: %-3s by %s agents\n" \
                "$type" "$name" "$frequency" "$agents"
        done << 'SQL'
SELECT 
    capability_type,
    capability_name,
    SUM(frequency) as total_requests,
    COUNT(DISTINCT requested_by_agent) as agent_count
FROM missing_capabilities
WHERE resolution_status = 'pending'
GROUP BY capability_type, capability_name
ORDER BY total_requests DESC;
SQL
    else
        echo -e "${GREEN}All capabilities available ✓${NC}"
    fi
    
    # Footer
    echo ""
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo -e "Refreshing every 3 seconds... Database: ${PURPLE}$(basename "$MEMORY_DB")${NC}"
    
    sleep 3
done