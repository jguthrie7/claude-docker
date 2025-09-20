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
- `claude-auth/` - Claude runtime data directory (contains OAuth credentials, todos, projects, etc.)

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
   - SSH access is provided via SSH agent forwarding (automatic - no setup needed)

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
- Configures git with your GitHub credentials (if provided)
- Mounts workspace and Claude's data directory for persistent authentication

### Authentication Persistence

Authentication and configuration persist between container restarts through two files:

1. **OAuth Credentials** (`claude-auth/.credentials.json`)
   - Contains your Claude.ai OAuth tokens
   - Created on first login with `/login` command
   - Mounted to `~/.claude/.credentials.json` in container

2. **Configuration State** (`claude-config.json`)
   - Contains user ID, settings, project history, and session state
   - Created automatically by Claude Code or during `make init`
   - Mounted to `~/.claude.json` in container
   - Ensures Claude Code recognizes you as the same user across restarts

Both files are excluded from git to protect your personal data.

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

**Container-level configuration:**
- Use `claude mcp add` inside the container
- Configurations persist in the mounted `claude-auth/` directory
- Available across all projects in this container instance

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

3. **API keys are passed via environment variables:**
   - Set in your `.env` file (already configured for Context7 and Firecrawl)
   - Environment variables are automatically available to MCP servers

### Alternative: Container-level MCP Configuration

1. **Using `claude mcp add` inside container:**
   ```bash
   make shell
   claude mcp add context7 --env UPSTASH_REDIS_REST_URL=${UPSTASH_REDIS_REST_URL} \
     --env UPSTASH_REDIS_REST_TOKEN=${UPSTASH_REDIS_REST_TOKEN} \
     -- npx @context7/mcp-server
   ```

2. **These configurations persist in the mounted `claude-auth/` directory between container restarts**

### Configuration Persistence

MCP configuration persists through:
- **Workspace configs**: `.mcp.json` files persist automatically via workspace mount
- **Container configs**: MCP servers added with `claude mcp add` persist in `claude-auth/`
- **Authentication**: Claude credentials persist in `claude-auth/`
- **Environment variables**: Available in all sessions via `.env` file

## Repository Structure

This repository uses `.gitkeep` files to preserve directory structure while keeping sensitive data private:

```
claude-docker/
├── workspace/           # Your code projects (not committed)
├── claude-auth/         # Claude data & OAuth credentials (not committed)
│   ├── .credentials.json  # OAuth tokens (created on first login)
│   ├── todos/             # Task tracking data
│   ├── projects/          # Project metadata
│   └── ...                # Other Claude runtime data
├── claude-config.json   # Claude configuration (user ID, settings) (not committed)
├── .env                 # Environment variables (not committed)
├── .env.example         # Template for environment setup
├── docker-compose.yml   # Container configuration
├── Dockerfile           # Container image definition
├── Makefile            # Development commands
└── CLAUDE.md           # This documentation
```

- **Committed to Git**: Directory structure, Docker configs, documentation
- **Not Committed**: API keys, authentication data, workspace files, Claude runtime data, user configuration
- **Setup Required**: Users must add their own `.env` file after cloning (`.claude-config.json` is created automatically)

## Security Considerations

- SSH access via secure agent forwarding (no keys copied to container)
- User runs with non-root privileges but has sudo access
- Authentication data persisted outside container
- Environment variables for API keys (not committed to git)
- Personal workspace and credentials excluded from version control