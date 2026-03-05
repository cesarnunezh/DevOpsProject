# DevOps Final Project - Winter 2026

**Student:** César Núñez  
**Date:** 03/11/2026

# Phase 1: Repository Setup and Version Control
**Objective:** Establish a professional version control foundation that supports collaborative development, automated deployments, and code quality standards.

**Deliverables:** 
- Four properly structured Git repositories
- Documentation explaining your Git workflow and branching strategy
- Screenshots demonstrating:
  - Initial setup of main and develop branches
    - database: ![](/images/phase1/database_init.png)
    - frontend-service:
    - order-service:
    - product-service:
  - Complete feature development workflow (from branch creation to merge)
    - database: ![](/images/phase1/database_feature1.png)![](/images/phase1/database_feature2.png)
    - frontend-service:
    - order-service:
    - product-service:
  - Complete release workflow (from develop to main)
    - database:
    - frontend-service:
    - order-service:
    - product-service:
  - Complete hotfix workflow (from main back to main and develop)
    - database:
    - frontend-service:
    - order-service:
    - product-service:
  - How all branch types interact in the Git Flow model
    - database:
    - frontend-service:
    - order-service:
    - product-service:
- Documentation explaining your design decisions and rationale

# Phase 2: Containerization with Docker
**Deliverables:** 
- Dockerfiles for all services
    - database: Available [here](https://github.com/cesarnunezh/database/blob/main/Dockerfile)
    - frontend-service: Available [here](https://github.com/cesarnunezh/frontend-service/blob/main/Dockerfile)
    - order-service: Available [here](https://github.com/cesarnunezh/order-service/blob/main/Dockerfile)
    - product-service: Available [here](https://github.com/cesarnunezh/product-service/blob/main/Dockerfile)
- Docker Compose configuration
  ```yaml
  services:

  web-dev:
    build:
      context: frontend-service
      target: dev
    image: cesarnunezh/frontend-service:dev
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-service:/app
      - /app/node_modules
    env_file: .env
    profiles:
      - dev

  web:
    build:
      context: frontend-service
      target: production
    image: cesarnunezh/frontend-service:prod
    ports:
      - "3000:80"
    env_file: .env
    profiles:
      - prod

  database:
    build:
      context: database
      target: database
    image: cesarnunezh/database-service:latest
    restart: unless-stopped
    env_file: .env
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d database"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - app-network

  orders-api:
    build: 
      context: order-service
      target: runtime
    image: cesarnunezh/orders-api:latest
    ports:
      - "8050:8050"
    env_file:
      - .env
    depends_on:
      database:
        condition: service_healthy
    networks:
      - app-network

  products-api:
    build: 
      context: product-service
      target: runtime
    image: cesarnunezh/products-api:latest
    ports:
      - "8070:8070"
    env_file:
      - .env
    depends_on:
      database:
        condition: service_healthy
    networks:
      - app-network

  networks:
    app-network:

  volumes:
    postgres_data:
  ```
- Container security scan reports
- Screenshot showing all images successfully pushed to Docker Hub: ![](./images/phase2/dockerhub.png)
- Docker Hub repository URLs for each service:
    - database: https://hub.docker.com/repository/docker/cesarnunezh/database-service/general
    - frontend-service: https://hub.docker.com/repository/docker/cesarnunezh/frontend-service/general
    - order-service: https://hub.docker.com/repository/docker/cesarnunezh/orders-api/general
    - product-service: https://hub.docker.com/repository/docker/cesarnunezh/products-api/general

# Phase 3: CI/CD Pipeline with Jenkins
**Deliverables:**
- Screenshots of Jenkins server with pipelines configured
- Jenkinsfiles for all services
- Screenshots of pipeline executions for each environment (Build, Dev, Staging, Prod)


# Phase 4: Infrastructure as Code with Terraform
**Deliverables:**
- Terraform modules and configurations
- State management setup
- Screenshots showing:
  - Terraform plan output for each environment
  - Successful terraform apply results
  - Running Minikube cluster and local resources
  - Terraform outputs that will be used by Jenkins


# Phase 5: Kubernetes Deployment
**Deliverables:**
- Kubernetes manifests for all services
- Screenshots showing:
  - Running pods in different namespaces
  - Services and ingress configuration
  - Successful deployment rollout
- Documentation explaining your deployment strategy (rolling updates, blue-green, or canary)

# Phase 6: Integration Validation
**Objective:** Demonstrate that all components work together as a complete DevOps pipeline.

**Deliverables:**
- Screenshots or screen recording showing the complete flow from code commit to production
- Evidence of successful deployments in all environments:
  - kubectl output showing running pods
  - Application accessible via browser/API
  - Correct image tags in each environment
- Brief report summarizing any challenges faced and how they were resolved


# Phase 7: DevOps Extensions
**Objective:** Extend the baseline e-commerce DevOps pipeline by implementing two practices (chosen from the first 10 DevOps topics presentation). The goal is to demonstrate the ability to integrate new DevOps capabilities into an existing system without breaking the delivery flow.

**Deliverables:**

##### Extension 1:
- Design:
  - Problem statement
  - Architecture/approach
  - Acceptance criteria
  - Integration points and environment behavior
- Implementation:
  - Config/code/manifests/scripts implementing the topic
  - Pipeline updates (Jenkinsfile/shared library changes) and/or GitOps config changes
  - Any supporting files (policies, rulesets, dashboards-as-code, test specs, runbooks)
- Execution:
  - Screenshots/log excerpts showing the feature running successfully
  - Outputs produced by the system (reports, scan results, metrics charts, test results, policy decisions, etc.)

##### Extension 2:

- Design:
  - Problem statement
  - Architecture/approach
  - Acceptance criteria
  - Integration points and environment behavior
- Implementation:
  - Config/code/manifests/scripts implementing the topic
  - Pipeline updates (Jenkinsfile/shared library changes) and/or GitOps config changes
  - Any supporting files (policies, rulesets, dashboards-as-code, test specs, runbooks)
- Execution:
  - Screenshots/log excerpts showing the feature running successfully
  - Outputs produced by the system (reports, scan results, metrics charts, test results, policy decisions, etc.)