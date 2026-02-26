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
    jq \
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

# Create workspace with proper permissions
RUN mkdir -p /workspace && \
    chown -R $USERNAME:$USERNAME /workspace

# Create XDG runtime directory for fish shell (avoids "Runtime path not available" error)
RUN mkdir -p /run/user/1000 && \
    chown $USERNAME:$USERNAME /run/user/1000 && \
    chmod 700 /run/user/1000
ENV XDG_RUNTIME_DIR=/run/user/1000
ENV PATH="/home/node/.local/bin:${PATH}"

# Switch to the user
USER $USERNAME
WORKDIR /workspace

# Install uv as the node user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Claude Code using native installer (installs to ~/.local/bin)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Set up fish configuration as the user
RUN mkdir -p /home/$USERNAME/.config/fish && \
    mkdir -p /home/$USERNAME/.local/share/fish && \
    printf '%s\n' "set -g fish_greeting ''" "fish_add_path -g \$HOME/.local/bin" > /home/$USERNAME/.config/fish/config.fish

# Create MCP servers directory structure for manual configuration
RUN mkdir -p /home/$USERNAME/.config/claude-code/mcp-servers && \
    mkdir -p /home/$USERNAME/.local/share/claude-code

# At the end of your Dockerfile, before CMD
USER $USERNAME

# Create simplified entrypoint script for git config and SSH setup
RUN echo '#!/bin/bash\n\
# Fix hostname resolution for sudo\n\
CURRENT_HOSTNAME=$(hostname)\n\
if ! grep -q "$CURRENT_HOSTNAME" /etc/hosts 2>/dev/null; then\n\
  echo "127.0.1.1 $CURRENT_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null\n\
fi\n\
\n\
# Fix SSH agent socket permissions if it exists\n\
if [ -e /ssh-agent ]; then\n\
  sudo chmod 666 /ssh-agent\n\
fi\n\
\n\
# Configure git if environment variables are provided\n\
if [ -n "$GITHUB_USER" ]; then\n\
  git config --global user.name "$GITHUB_USER"\n\
fi\n\
if [ -n "$GITHUB_EMAIL" ]; then\n\
  git config --global user.email "$GITHUB_EMAIL"\n\
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
# Configure MCP servers at user scope if not already configured\n\
if ! claude mcp list --scope user 2>/dev/null | grep -q "context7"; then\n\
  echo "Configuring Context7 MCP server..."\n\
  claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest || true\n\
fi\n\
if ! claude mcp list --scope user 2>/dev/null | grep -q "reddit"; then\n\
  echo "Configuring Reddit MCP server..."\n\
  claude mcp add reddit --scope user -- uvx mcp-server-reddit || true\n\
fi\n\
if ! claude mcp list --scope user 2>/dev/null | grep -q "youtube"; then\n\
  echo "Configuring YouTube MCP server..."\n\
  claude mcp add youtube --scope user --transport stdio --env YOUTUBE_API_KEY="$YOUTUBE_API_KEY" -- npx -y @kirbah/mcp-youtube || true\n\
fi\n\
if ! claude mcp list --scope user 2>/dev/null | grep -q "playwright"; then\n\
  echo "Configuring Playwright MCP server..."\n\
  claude mcp add playwright --scope user -- npx @playwright/mcp@latest || true\n\
fi\n\
\n\
exec "$@"' > /home/$USERNAME/entrypoint.sh && \
chmod +x /home/$USERNAME/entrypoint.sh

ENTRYPOINT ["/home/node/entrypoint.sh"]

# Use bash as default, can switch to fish once inside
CMD ["bash"]
