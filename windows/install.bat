@echo off
REM Claude Code Agent Orchestrator Installation Script for Windows
REM https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator

echo.
echo Claude Code Agent Orchestrator Installer
echo ==========================================
echo.

REM Check if Claude directory exists
set CLAUDE_DIR=%USERPROFILE%\.claude
if not exist "%CLAUDE_DIR%" (
    echo Error: Claude configuration directory not found at: %CLAUDE_DIR%
    echo Please ensure Claude Code is installed first
    pause
    exit /b 1
)

echo Found Claude directory at: %CLAUDE_DIR%
echo.

REM Create directories if they don't exist
echo Creating required directories...
if not exist "%CLAUDE_DIR%\agents" mkdir "%CLAUDE_DIR%\agents"
if not exist "%CLAUDE_DIR%\agent-workspaces" mkdir "%CLAUDE_DIR%\agent-workspaces"
if not exist "%CLAUDE_DIR%\agent-archives" mkdir "%CLAUDE_DIR%\agent-archives"

REM Copy agent files
echo Installing agents...
xcopy agents\* "%CLAUDE_DIR%\agents\" /E /I /Y >nul 2>&1
if errorlevel 1 (
    echo Error: Failed to copy agent files. Are you running this from the repository root?
    pause
    exit /b 1
)

REM Count installed agents
set /a AGENT_COUNT=0
for %%f in ("%CLAUDE_DIR%\agents\*.md") do set /a AGENT_COUNT+=1
echo Installed %AGENT_COUNT% agents

REM Verify key files
echo.
echo Verifying installation...

if exist "%CLAUDE_DIR%\agents\orchestration-agent.md" (
    echo - Orchestration agent installed
) else (
    echo - ERROR: Orchestration agent missing
)

if exist "%CLAUDE_DIR%\agents\agent-registry.json" (
    echo - Agent registry installed
) else (
    echo - ERROR: Agent registry missing
)

if exist "%CLAUDE_DIR%\agents\agent-output-schema.json" (
    echo - Output schema installed
) else (
    echo - ERROR: Output schema missing
)

REM Installation complete
echo.
echo ==========================================
echo Installation complete!
echo.
echo Next steps:
echo 1. Restart Claude Code to load the new agents
echo 2. Try: "I want to build a SaaS product" to see orchestration in action
echo 3. Check %CLAUDE_DIR%\agent-workspaces\ for agent activity logs
echo.
echo Documentation:
echo - Quick Start: %CLAUDE_DIR%\agents\AGENT-QUICK-START.md
echo - Full Guide: %CLAUDE_DIR%\agents\AGENT-COMPLETE-GUIDE.md
echo.
echo Happy orchestrating!
echo.
pause