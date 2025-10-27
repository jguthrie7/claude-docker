# Claude Code Docker Development Environment
# Simple commands for managing the development container

# Container configuration
SERVICE_NAME := claude-dev
DOCKER_COMPOSE := docker-compose
DOCKER_EXEC := docker-compose exec

# Load PROJECT_NAME from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

# Generate unique project name: PROJECT_NAME + path hash for guaranteed isolation
CURRENT_DIR := $(realpath $(CURDIR))
PATH_HASH := $(shell echo "$(CURRENT_DIR)" | shasum -a 256 | cut -c1-8)
PROJECT_NAME ?= claude-docker
export COMPOSE_PROJECT_NAME := $(PROJECT_NAME)-$(PATH_HASH)

# Platform detection for SSH forwarding
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    # macOS - use Docker Desktop's SSH forwarding
    export SSH_MOUNT := /run/host-services/ssh-auth.sock:/ssh-agent
    export SSH_SOCK := /ssh-agent
else ifdef SSH_AUTH_SOCK
    # Linux/WSL with SSH agent running
    export SSH_MOUNT := $(SSH_AUTH_SOCK):/ssh-agent
    export SSH_SOCK := /ssh-agent
else
    # No SSH agent or unsupported platform - use dummy mount that won't break compose
    export SSH_MOUNT := /dev/null:/dev/null
    export SSH_SOCK :=
endif

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m
BOLD := \033[1m

# Default target
.DEFAULT_GOAL := help

# Ensure all targets are phony
.PHONY: help init up down restart build shell bash fish logs status clean claude doctor exec root attach rebuild yolo

## Show this help message
help:
	@echo "$(BOLD)$(CYAN)Claude Code Docker Environment$(RESET)"
	@echo ""
	@echo "$(BOLD)Setup Commands:$(RESET)"
	@echo "  $(GREEN)init$(RESET)     - First-time setup (copy .env.example, create directories)"
	@echo "  $(GREEN)build$(RESET)    - Build the container from scratch"
	@echo ""
	@echo "$(BOLD)Container Management:$(RESET)"
	@echo "  $(GREEN)up$(RESET)       - Start container in background"
	@echo "  $(GREEN)down$(RESET)     - Stop container"
	@echo "  $(GREEN)restart$(RESET)  - Restart container"
	@echo "  $(GREEN)rebuild$(RESET)  - Stop, rebuild, and start container"
	@echo "  $(GREEN)status$(RESET)   - Check if container is running"
	@echo "  $(GREEN)logs$(RESET)     - Show container logs"
	@echo "  $(GREEN)attach$(RESET)   - Attach to running container (foreground)"
	@echo ""
	@echo "$(BOLD)Shell Access:$(RESET)"
	@echo "  $(GREEN)shell$(RESET)    - Open bash shell in container"
	@echo "  $(GREEN)bash$(RESET)     - Open bash shell in container"
	@echo "  $(GREEN)fish$(RESET)     - Open fish shell in container"
	@echo "  $(GREEN)root$(RESET)     - Open root shell for debugging"
	@echo ""
	@echo "$(BOLD)Development:$(RESET)"
	@echo "  $(GREEN)claude$(RESET)   - Run Claude Code directly"
	@echo "  $(GREEN)doctor$(RESET)   - Run Claude Code /doctor command"
	@echo "  $(GREEN)yolo$(RESET)     - Run Claude Code in YOLO mode (bypass all permissions)"
	@echo "  $(GREEN)exec$(RESET)     - Run custom command (use: make exec CMD=\"command\")"
	@echo ""
	@echo "$(BOLD)Cleanup:$(RESET)"
	@echo "  $(GREEN)clean$(RESET)    - Stop container and remove volumes"
	@echo ""
	@echo "$(YELLOW)Quick start: make init && make up && make shell$(RESET)"

## First-time setup: copy .env.example and ensure directories exist
init:
	@echo "$(CYAN)Setting up environment...$(RESET)"
	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo "$(GREEN)✓$(RESET) Created .env file from .env.example"; \
		echo "$(YELLOW)⚠$(RESET)  Edit .env file with your API keys and GitHub credentials"; \
	else \
		echo "$(YELLOW)⚠$(RESET)  .env file already exists"; \
	fi
	@echo "$(GREEN)✓$(RESET) claude-config.json template already exists in repository"
	@echo "$(GREEN)✓$(RESET) Setup complete. Edit .env file, then run: make up"

## Build the container from scratch
build:
	@echo "$(CYAN)Building container...$(RESET)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✓$(RESET) Container built successfully"

## Start container in background
up:
	@echo "$(CYAN)Starting container...$(RESET)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✓$(RESET) Container started. Use 'make shell' to access it"

## Stop container
down:
	@echo "$(CYAN)Stopping container...$(RESET)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓$(RESET) Container stopped"

## Restart container
restart: down up

## Stop, rebuild, and start container
rebuild: down build up

## Check if container is running
status:
	@echo "$(CYAN)Container status:$(RESET)"
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(GREEN)✓$(RESET) Container is running"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) ps aux | head -5; \
	else \
		echo "$(RED)✗$(RESET) Container is not running"; \
	fi

## Show container logs
logs:
	@$(DOCKER_COMPOSE) logs -f

## Attach to running container (foreground)
attach:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Attaching to container...$(RESET)"; \
		$(DOCKER_COMPOSE) attach $(SERVICE_NAME); \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Open bash shell in container
shell: bash

## Open bash shell in container
bash:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Opening bash shell...$(RESET)"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) bash; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Open fish shell in container
fish:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Opening fish shell...$(RESET)"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) fish; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Open root shell for debugging
root:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Opening root shell...$(RESET)"; \
		$(DOCKER_COMPOSE) exec -u root $(SERVICE_NAME) bash; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Run Claude Code directly
claude:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Starting Claude Code...$(RESET)"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) claude; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Run Claude Code /doctor command
doctor:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Running Claude Code diagnostics...$(RESET)"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) claude /doctor; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Run Claude Code in YOLO mode (bypass all permissions)
yolo:
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(RED)⚠️  YOLO MODE: Running Claude Code with ALL permissions bypassed$(RESET)"; \
		echo "$(YELLOW)Claude will execute all commands without asking for confirmation!$(RESET)"; \
		echo ""; \
		$(DOCKER_EXEC) $(SERVICE_NAME) claude --dangerously-skip-permissions; \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Run custom command in container (use: make exec CMD="command")
exec:
	@if [ -z "$(CMD)" ]; then \
		echo "$(RED)✗$(RESET) Please specify a command: make exec CMD=\"your-command\""; \
		exit 1; \
	fi
	@if [ "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME))" ]; then \
		echo "$(CYAN)Running: $(CMD)$(RESET)"; \
		$(DOCKER_EXEC) $(SERVICE_NAME) $(CMD); \
	else \
		echo "$(RED)✗$(RESET) Container is not running. Start it with: make up"; \
		exit 1; \
	fi

## Stop container and remove volumes
clean:
	@echo "$(CYAN)Cleaning up...$(RESET)"
	@$(DOCKER_COMPOSE) down -v
	@docker system prune -f
	@echo "$(GREEN)✓$(RESET) Cleanup complete"