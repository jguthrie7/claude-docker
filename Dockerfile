FROM node:20-bookworm-slim

# Install minimal development tools and dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    htop \
    tmux \
    fish \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Use existing node user (UID 1000) and configure for development
ARG USERNAME=node

# Configure sudo access and ensure home directory is properly owned
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/$USERNAME/.config && \
    mkdir -p /home/$USERNAME/.local/share && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# Install Claude Code globally (the only npm package we need)
RUN npm install -g @anthropic-ai/claude-code

# Fix npm global permissions for Claude Code auto-updates
# ARG needs to be re-declared after FROM to be available in RUN commands
ARG USERNAME
RUN chown -R ${USERNAME}:${USERNAME} /usr/local

# Create workspace with proper permissions
RUN mkdir -p /workspace && \
    chown -R $USERNAME:$USERNAME /workspace

# Switch to the user
USER $USERNAME
WORKDIR /workspace

# Set up fish configuration as the user
RUN mkdir -p /home/$USERNAME/.config/fish && \
    mkdir -p /home/$USERNAME/.local/share/fish && \
    echo "set -g fish_greeting ''" > /home/$USERNAME/.config/fish/config.fish

# Create MCP servers directory structure for manual configuration
RUN mkdir -p /home/$USERNAME/.config/claude-code/mcp-servers && \
    mkdir -p /home/$USERNAME/.local/share/claude-code

# At the end of your Dockerfile, before CMD
USER $USERNAME

# Create entrypoint script to auto-configure git and restore .claude.json
RUN echo '#!/bin/bash\n\
# Configure git if environment variables are provided\n\
if [ -n "$GITHUB_USER" ]; then\n\
  git config --global user.name "$GITHUB_USER"\n\
fi\n\
if [ -n "$GITHUB_EMAIL" ]; then\n\
  git config --global user.email "$GITHUB_EMAIL"\n\
fi\n\
\n\
# Initialize .claude.json only on first run (if it doesn'\''t exist)\n\
if [ -f /home/'$USERNAME'/config-backup/.claude.json ] && [ ! -f /home/'$USERNAME'/.claude.json ]; then\n\
  cp /home/'$USERNAME'/config-backup/.claude.json /home/'$USERNAME'/.claude.json\n\
fi\n\
\n\
# Fix SSH agent socket permissions if it exists\n\
if [ -S /ssh-agent ]; then\n\
  chown '$USERNAME':'$USERNAME' /ssh-agent\n\
fi\n\
\n\
# Set up SSH directory and known hosts for seamless GitHub access\n\
mkdir -p /home/'$USERNAME'/.ssh\n\
chmod 700 /home/'$USERNAME'/.ssh\n\
\n\
# Add GitHub'\''s official SSH host keys to known_hosts\n\
cat >> /home/'$USERNAME'/.ssh/known_hosts << '\''EOL'\''\n\
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl\n\
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=\n\
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==\n\
EOL\n\
\n\
chmod 644 /home/'$USERNAME'/.ssh/known_hosts\n\
chown -R '$USERNAME':'$USERNAME' /home/'$USERNAME'/.ssh\n\
\n\
exec "$@"' > /home/$USERNAME/entrypoint.sh && \
chmod +x /home/$USERNAME/entrypoint.sh

ENTRYPOINT ["/home/node/entrypoint.sh"]

# Use bash as default, can switch to fish once inside
CMD ["bash"]
