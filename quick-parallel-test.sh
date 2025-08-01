#!/bin/bash
# Quick parallel orchestration test

echo "🎭 Quick Parallel Orchestration Test"
echo "==================================="
echo ""
echo "This test will show you how parallel orchestration works."
echo ""

# Check if test was already created
if [ -d "/Users/fred/parallel-orchestration-test" ]; then
    echo "✅ Test workspace already exists at: /Users/fred/parallel-orchestration-test"
    echo ""
    echo "📋 To run the test:"
    echo ""
    echo "1. Open 4 terminal windows"
    echo ""
    echo "2. In Terminal 1, navigate to backend task:"
    echo "   cd /Users/fred/parallel-orchestration-test/src/backend"
    echo "   cat TASK.md  # See the backend task"
    echo ""
    echo "3. In Terminal 2, navigate to frontend task:"
    echo "   cd /Users/fred/parallel-orchestration-test/src/frontend"
    echo "   cat TASK.md  # See the frontend task"
    echo ""
    echo "4. In Terminal 3, navigate to database task:"
    echo "   cd /Users/fred/parallel-orchestration-test/src/database"
    echo "   cat TASK.md  # See the database task"
    echo ""
    echo "5. In Terminal 4, navigate to infrastructure task:"
    echo "   cd /Users/fred/parallel-orchestration-test/src/infrastructure"
    echo "   cat TASK.md  # See the DevOps task"
    echo ""
    echo "🚀 In each terminal, you would normally run Claude Code and have"
    echo "   the agent complete the task. The agents would work in parallel!"
    echo ""
    echo "📊 To see what monitoring would look like with active agents:"
    echo "   ./show-sample-monitoring.sh"
else
    echo "❌ Test workspace not found. Run: ./test-parallel-orchestration.sh first"
fi