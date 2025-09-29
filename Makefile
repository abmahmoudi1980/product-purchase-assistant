# Product Purchase Assistant - Docker Management

.PHONY: help dev prod build clean logs shell

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start development environment with hot reloading
	docker compose -f docker-compose.dev.yml up

dev-build: ## Build and start development environment
	docker compose -f docker-compose.dev.yml up --build

dev-daemon: ## Start development environment in background
	docker compose -f docker-compose.dev.yml up -d

prod: ## Start production environment
	docker compose -f docker-compose.prod.yml up --build

prod-daemon: ## Start production environment in background
	docker compose -f docker-compose.prod.yml up -d --build

build: ## Build all Docker images
	docker compose -f docker-compose.dev.yml build
	docker compose -f docker-compose.prod.yml build

clean: ## Stop all containers and remove volumes
	docker compose -f docker-compose.dev.yml down -v
	docker compose -f docker-compose.prod.yml down -v
	docker system prune -f

clean-all: ## Remove everything including images
	docker compose -f docker-compose.dev.yml down -v --rmi all
	docker compose -f docker-compose.prod.yml down -v --rmi all
	docker system prune -a -f

logs: ## Show logs for all services
	docker compose -f docker-compose.dev.yml logs -f

logs-backend: ## Show backend logs
	docker compose -f docker-compose.dev.yml logs -f backend

logs-frontend: ## Show frontend logs
	docker compose -f docker-compose.dev.yml logs -f frontend

shell-backend: ## Open shell in backend container
	docker compose -f docker-compose.dev.yml exec backend bash

shell-frontend: ## Open shell in frontend container
	docker compose -f docker-compose.dev.yml exec frontend sh

stop: ## Stop development environment
	docker compose -f docker-compose.dev.yml down

stop-prod: ## Stop production environment
	docker compose -f docker-compose.prod.yml down

restart: ## Restart development environment
	make stop
	make dev

config: ## Validate docker-compose configuration
	docker compose -f docker-compose.dev.yml config
	docker compose -f docker-compose.prod.yml config

status: ## Show container status
	docker compose -f docker-compose.dev.yml ps