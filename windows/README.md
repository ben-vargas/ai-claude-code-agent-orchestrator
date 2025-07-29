# Windows Installation Guide

This guide is for Windows users who want to install the Claude Code Agent Orchestrator.

## Prerequisites

- Claude Code (Claude Desktop) installed on Windows
- Administrator privileges may be required

## Installation Steps

### Option 1: Automated Installation

1. Open Command Prompt or PowerShell as Administrator
2. Navigate to the repository directory:
   ```cmd
   cd path\to\Claude-Code-Agent-Orchestrator\windows
   ```
3. Run the installation script:
   ```cmd
   install.bat
   ```

### Option 2: Manual Installation

1. Open Command Prompt or PowerShell
2. Create the required directories:
   ```cmd
   mkdir "%USERPROFILE%\.claude\agents"
   mkdir "%USERPROFILE%\.claude\agent-workspaces"
   ```
3. Copy the agent files:
   ```cmd
   xcopy ..\agents\* "%USERPROFILE%\.claude\agents\" /E /I
   ```
4. Restart Claude Code

## Troubleshooting

### Permission Issues
- Run Command Prompt as Administrator
- Check Windows Defender or antivirus settings

### Path Issues
- Use quotes around paths with spaces
- Use %USERPROFILE% instead of ~ 

### Agent Loading Issues
- Verify files copied correctly: `dir "%USERPROFILE%\.claude\agents"`
- Check file permissions
- Restart Claude Code completely (not just reload)

## Differences from macOS

- File paths use backslashes (\) instead of forward slashes (/)
- Home directory is %USERPROFILE% instead of ~
- Some shell scripts may need PowerShell equivalents
- File permissions work differently

## Support

For Windows-specific issues, please open an issue on GitHub with the "windows" label.