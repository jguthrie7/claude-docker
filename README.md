# Claude Code Docker Environment

A containerized development environment for [Claude Code](https://claude.ai/code) with all necessary tools and configurations pre-installed.

## Features

✨ **Pre-configured Development Environment**
- Claude Code installed and ready to use
- Node.js 20 with npm and modern development tools
- Fish and Bash shells available
- Automatic git configuration from environment variables

🔒 **Secure & Isolated**
- Runs in Docker container with proper user permissions
- SSH keys mounted read-only
- Authentication data persisted outside container

🚀 **Easy to Use**
- Simple Makefile commands for all operations
- One-command setup and start
- Auto-restores Claude configuration

## Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on Mac/Linux)

### Setup

1. **Clone and initialize:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-docker.git
   cd claude-docker
   make init
   ```

2. **Configure environment:**
   ```bash
   # Edit .env file with your API keys and GitHub credentials
   vim .env
   ```

3. **Start the environment:**
   ```bash
   make up
   make shell
   ```

That's it! You're now in a fully configured Claude Code environment.

## Usage

### Essential Commands

```bash
make help      # Show all available commands
make up        # Start the container
make shell     # Open bash shell in container
make fish      # Open fish shell in container
make down      # Stop the container
make claude    # Run Claude Code directly
```

### Daily Workflow

```bash
# Start your development session
make up && make shell

# When you're done
make down
```

## What's Included

- **Claude Code**: Latest version with auto-update permissions
- **Development Tools**: git, curl, wget, vim, nano, build-essential
- **Languages**: Node.js 20, Python 3, npm
- **Shells**: Bash (default) and Fish
- **Utilities**: ripgrep, htop, tmux, sudo access

## Configuration

### Environment Variables

Create and edit `.env` file (use `make init` to get started):

```bash
# GitHub Configuration (optional, enables git auto-config)
GITHUB_USER=your-github-username
GITHUB_EMAIL=your-email@example.com

# MCP API Keys
FIRECRAWL_API_KEY=your-firecrawl-api-key
UPSTASH_REDIS_REST_URL=your-upstash-redis-url
UPSTASH_REDIS_REST_TOKEN=your-upstash-redis-token
```

### SSH Access (Optional)

SSH access from inside the container is **optional**. Only set this up if you need to access Git repositories or remote servers from within the Claude Code environment.

**SSH Agent Forwarding (Automatic)**

SSH forwarding is automatically configured based on your platform when you use the Makefile commands. No manual configuration needed!

```bash
# 1. Ensure your SSH agent has keys loaded (one-time setup)
ssh-add ~/.ssh/id_ed25519  # or your key name
ssh-add -l  # Verify keys are loaded

# 2. That's it! SSH forwarding will work automatically
make up
make shell

# 3. Test inside the container
ssh -T git@github.com
```


## Directory Structure

```
├── workspace/          # Your development files (mounted)
├── claude-auth/        # Claude authentication data
├── home-config/       # User configuration backup
└── mcp-servers/       # MCP server configurations
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Detailed documentation for Claude Code instances
- **[.env.example](.env.example)** - Environment variable template

## Security Considerations

### Data Protection
- **Credentials**: All sensitive data (API keys, tokens) stays on the host system
- **Isolation**: The container runs with non-root user privileges
- **Persistence**: Only configuration and workspace data is persisted between runs
- **Network**: Uses host networking for development convenience

### Best Practices
- **Never commit** your `.env` file or any files in ignored directories
- **SSH access** uses secure agent forwarding (no keys in container)
- **Regularly update** the container by running `make rebuild`
- **Monitor** what tools and permissions you grant to Claude Code

### What Gets Persisted
- ✅ Workspace files (`workspace/`)
- ✅ Claude authentication (`claude-auth/`)
- ✅ MCP server configurations (`mcp-servers/`)
- ✅ User configurations (`home-config/`)
- ❌ Container filesystem changes
- ❌ Installed packages (use Dockerfile for permanent changes)

## Troubleshooting

### Container won't start
```bash
make logs    # Check container logs
make status  # Check container status
```

### Permission issues
```bash
make root    # Open root shell for debugging
```

### SSH access issues
```bash
# Check if SSH agent is running and has keys loaded
ssh-add -l

# If no keys are loaded, add them:
ssh-add ~/.ssh/id_ed25519  # or your key name

# Test SSH from inside container:
make shell
ssh -T git@github.com
```

### Reset everything
```bash
make clean   # Stop and remove everything
make build   # Rebuild from scratch
```

## Contributing

1. Fork the repository
2. Make your changes
3. Test with `make rebuild`
4. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

---

**Need help?** Run `make help` to see all available commands or check the [detailed documentation](CLAUDE.md).