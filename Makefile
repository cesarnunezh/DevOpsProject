.DEFAULT_GOAL := help
SHELL := /bin/bash
include .env

help:
	@echo "Available commands:"
	@echo "make clone-services        Clone all microservice repos"
	@echo "make build ENV=dev|prod   Build containers"
	@echo "make up ENV=dev|prod      Start services"
	@echo "make down                 Stop services"
	@echo "make logs                 Show logs"
	@echo "make test                 Run tests"
	@echo "make push ENV=prod        Push images to Docker Hub"
	@echo "make clean                Remove containers and volumes"

# -----------------------------
# Variables
# -----------------------------
COMPOSE = docker compose
PROFILE = --profile $(ENV)
REPO_OWNER = cesarnunezh
SERVICES = frontend-service order-service product-service database

# -----------------------------
# Clone service repos
# -----------------------------
clone-services:
	@echo "Cloning microservice repositories..."
	@for svc in $(SERVICES); do \
		if [ -d "$$svc/.git" ]; then \
			echo "$$svc already present (git repo found), skipping."; \
		elif [ -d "$$svc" ]; then \
			echo "$$svc exists but is not a git repo, skipping."; \
		else \
			git clone https://github.com/$(REPO_OWNER)/$$svc.git $$svc; \
		fi; \
	done

# -----------------------------
# Build containers
# -----------------------------
build:
	@echo "Building containers for $(ENV)..."
	$(COMPOSE) $(PROFILE) build

# -----------------------------
# Start services
# -----------------------------
up:
	@echo "Starting services in $(ENV) mode..."
	$(COMPOSE) $(PROFILE) up -d

# -----------------------------
# Show logs
# -----------------------------
logs:
	$(COMPOSE) $(PROFILE) logs -f --tail=150

# -----------------------------
# Stop services
# -----------------------------
down:
	@echo "Stopping services..."
	$(COMPOSE) down

# -----------------------------
# Run tests
# -----------------------------
test:
	@echo "Running tests for orders-api..."
	docker compose run --rm orders-api pytest

	@echo "Running tests for products-api..."
	docker compose run --rm products-api pytest

# -----------------------------
# Push images to Docker Hub
# -----------------------------
push:
ifeq ($(ENV),prod)
	@echo "Pushing images to Docker Hub..."
	$(COMPOSE) $(PROFILE) push
else
	@echo "Skipping push because ENV=$(ENV)"
endif

# -----------------------------
# Clean containers, volumes, images
# -----------------------------
clean:
	@echo "Cleaning Docker resources..."
	$(COMPOSE) -p devopsproject $(PROFILE) down --remove-orphans --rmi local -v	

# -----------------------------
# Security scans with trivy
# -----------------------------
scan:
	mkdir -p security-reports; \
	images=( \
		cesarnunezh/orders-api:latest \
		cesarnunezh/products-api:latest \
		cesarnunezh/frontend-service:$(ENV) \
		cesarnunezh/database-service:latest \
	); \
	for image in $${images[@]}; do \
		name=$$(echo $$image | cut -d'/' -f2 | cut -d':' -f1); \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $$PWD:/work -w /work \
			aquasec/trivy:latest image $$image \
			--scanners vuln \
			--severity CRITICAL,HIGH,MEDIUM \
			--format table \
			--output security-reports/$${name}.trivy.txt; \
		echo "Scan completed for $$image"; \
	done
