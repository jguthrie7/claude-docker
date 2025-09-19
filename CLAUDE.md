# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Docker-based development environment for Claude Code, providing a containerized workspace with all necessary tools and configurations.

## Architecture

### Container Structure
- **Base Image**: Node.js 20 on Debian Bookworm Slim
- **Main Service**: `claude-dev` container with Claude Code pre-installed
- **User Setup**: Non-root user with sudo privileges
- **Resource Limits**: 4GB memory, 2 CPU cores

### Directory Structure
- `workspace/` - Main development workspace (mounted into container)
- `claude-auth/` - Claude authentication and session data
- `home-config/` - Backup location for user configurations
- `ssh/` - SSH keys (mounted read-only for security)
- `mcp-servers/` - MCP server configuration directory

## Initial Setup

### Quick Start

1. **Initialize the environment:**
   ```bash
   make init
   ```
   This copies `.env.example` to `.env` and sets up the directory structure.

2. **Configure your environment:**
   - Edit `.env` file with your personal values:
     - Add your GitHub username/email (optional, enables automatic git configuration)
     - Add your Firecrawl API key from https://firecrawl.dev/
     - Add your Upstash Redis credentials from https://console.upstash.com/ (for Context7 MCP)
   - Place your SSH keys in the `ssh/` directory:
     ```bash
     cp ~/.ssh/id_ed25519* ssh/
     ```

3. **Start the environment:**
   ```bash
   make up
   ```

4. **Access the container:**
   ```bash
   make shell
   ```

**That's it!** Use `make help` to see all available commands.

## Available Commands

Use the Makefile for easy container management. Run `make help` to see all commands:

### Essential Commands
```bash
make help      # Show all available commands
make init      # First-time setup
make up        # Start container
make shell     # Open bash shell
make fish      # Open fish shell
make down      # Stop container
make restart   # Restart container
```

### Development Commands
```bash
make claude    # Run Claude Code directly
make doctor    # Run Claude Code diagnostics
make logs      # View container logs
make status    # Check container status
```

### Advanced Commands
```bash
make build     # Rebuild container from scratch
make rebuild   # Stop, rebuild, and start
make root      # Open root shell for debugging
make clean     # Stop and clean up everything
```

**Note**: The container runs as user `node` (UID 1000) for compatibility across different systems.

### Environment Setup
The container automatically:
- Installs Claude Code globally via npm
- Sets up user permissions and sudo access
- Configures fish shell
- Restores `.claude.json` configuration if available
- Configures git with your GitHub credentials (if provided)
- Mounts workspace and authentication directories

### Common Workflows

**Daily development:**
```bash
make up && make shell
```

**After making changes to Dockerfile:**
```bash
make rebuild
```

**Debugging issues:**
```bash
make doctor    # Check Claude Code status
make logs      # View container logs
make status    # Check if container is running
```

## Configuration Files

### Environment Variables (.env)
- `GITHUB_USER/GITHUB_EMAIL` - Git configuration (optional, automatically applied)
- `FIRECRAWL_API_KEY` - API key for Firecrawl MCP server
- `UPSTASH_REDIS_REST_URL/TOKEN` - Redis configuration for Context7 MCP

#### Git Auto-Configuration
When you set `GITHUB_USER` and `GITHUB_EMAIL` in your `.env` file, git is automatically configured on container startup:
- `git config --global user.name` is set to your GitHub username
- `git config --global user.email` is set to your email address
- This enables seamless git operations without manual configuration

### Docker Compose
- Host networking enabled for seamless development
- Volume mounts preserve authentication, SSH keys, and workspace
- Security: SSH keys mounted read-only

## MCP Server Integration

The environment supports MCP (Model Context Protocol) servers with persistent configuration:

### Configuration Methods

**Project-level configuration (recommended):**
- Create `.mcp.json` files in your workspace root
- These files persist automatically as the workspace is mounted
- Configuration is project-specific and version-controlled

**User-level configuration:**
- Configuration directory: `~/.config/claude-code/mcp-servers/` (now properly mounted)
- Global MCP servers available across all projects
- Place configurations in `./mcp-servers/` directory on the host

### Setting Up MCP Servers

1. **Create a project-level .mcp.json file in your workspace:**
   ```json
   {
     "mcpServers": {
       "filesystem": {
         "command": "npx",
         "args": ["@modelcontextprotocol/server-filesystem"],
         "env": {
           "ALLOWED_PATHS": "/workspace"
         }
       },
       "context7": {
         "command": "npx",
         "args": ["@context7/mcp-server"],
         "env": {
           "UPSTASH_REDIS_REST_URL": "${UPSTASH_REDIS_REST_URL}",
           "UPSTASH_REDIS_REST_TOKEN": "${UPSTASH_REDIS_REST_TOKEN}"
         }
       }
     }
   }
   ```

2. **Enable specific servers in Claude Code:**
   - Use `claude config set enabledMcpjsonServers filesystem,context7`
   - Or configure in your project's `.claude/settings.json`:
     ```json
     {
       "enabledMcpjsonServers": ["filesystem", "context7"]
     }
     ```

3. **API keys are passed via environment variables:**
   - Set in your `.env` file (already configured for Context7 and Firecrawl)
   - Environment variables are automatically available to MCP servers

### Configuration Persistence

**MCP configuration persistence is now fully supported with two methods:**

**Method 1: Using `claude mcp add` (Recommended)**
- Run `claude mcp add <name> <command>` inside the container
- Configurations are automatically persisted to `./home-config/.claude.json`
- All MCP servers added this way persist between container restarts
- Example:
  ```bash
  make shell
  claude mcp add context7 --env UPSTASH_REDIS_REST_URL=${UPSTASH_REDIS_REST_URL} \
    --env UPSTASH_REDIS_REST_TOKEN=${UPSTASH_REDIS_REST_TOKEN} \
    -- npx @context7/mcp-server
  ```

**Method 2: Project-level .mcp.json files**
- Create `.mcp.json` files in your workspace root (as shown in examples above)
- Enable with: `claude config set enabledMcpjsonServers server1,server2`
- Configurations are project-specific and version-controlled

### Persistence Details

MCP configuration persists properly between container restarts through:
- **Direct mount**: `.claude.json` file directly mounted from `./home-config/`
- **Workspace configs**: `.mcp.json` files persist automatically via workspace mount
- **User-level configs**: MCP server directory mounted from `./mcp-servers/`
- **Authentication**: Claude credentials persist in `./claude-auth/`
- **Environment variables**: Available in all sessions via `.env` file

### Troubleshooting MCP Persistence

If MCP servers disappear after restart:
1. Check if servers were added with `claude mcp add` (these should persist)
2. Verify `.claude.json` exists in `./home-config/` directory
3. Run `claude mcp list` to see configured servers
4. Check that environment variables are set in `.env` file

## Repository Structure

This repository uses `.gitkeep` files to preserve directory structure while keeping sensitive data private:

- **Committed to Git**: Directory structure, Docker configs, documentation
- **Not Committed**: Personal SSH keys, API keys, authentication data, workspace files
- **Setup Required**: Users must add their own `.env` file and SSH keys after cloning

## Security Considerations

- SSH keys mounted read-only
- User runs with non-root privileges but has sudo access
- Authentication data persisted outside container
- Environment variables for API keys (not committed to git)
- Personal workspace and credentials excluded from version control