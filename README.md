# DevOps Learning Project - PHP Hello World

A simple PHP application demonstrating modern DevOps practices with automated CI/CD pipelines deployed on Google Cloud.

## Overview

This project is a basic "Hello World" PHP web application built to explore and implement DevOps concepts including:
- Containerization with Docker
- GitHub Actions for CI/CD
- Automated testing with PHPUnit
- Container registry management (GitHub Container Registry)
- Deployment automation to Google Cloud servers

## Tech Stack

- **Language**: PHP 8.2
- **Web Server**: Apache
- **Testing**: PHPUnit 9.5
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Registry**: GitHub Container Registry (ghcr.io)
- **Deployment**: Google Cloud VM

## Local Development

### Prerequisites

- Docker and Docker Compose
- PHP 8.2+ (for local testing without Docker)
- Composer (for dependency management)

### Running Locally

1. Clone the repository:
```bash
git clone https://github.com/viksnekristians/devops_test.git
cd devops_test
```

2. Using Docker:
```bash
docker build -t php-hello-world .
docker run -p 8080:80 php-hello-world
```
Access the application at `http://localhost:8080`

3. Without Docker:
```bash
composer install
php -S localhost:8080
```

### Running Tests

```bash
composer test
# or
vendor/bin/phpunit tests
```

## CI/CD Pipelines

### 1. PR Check Pipeline (`pr-checks.yml`)

**Trigger**: Pull requests to main branch

**Purpose**: Validates code quality before merging

**Steps**:
- Runs PHPUnit tests
- Builds Docker image
- Performs basic validation

### 2. CI Pipeline (`ci.yml`)

**Trigger**: Push to main branch or manual dispatch

**Purpose**: Comprehensive testing and artifact creation

**Steps**:
- Runs full test suite
- Builds production Docker image
- Pushes to GitHub Container Registry with multiple tags:
  - `latest` (for main branch)
  - `sha-{commit}` (unique identifier)
  - Version tags (if tagged release)

### 3. Deploy Pipeline (`deploy.yml`)

**Trigger**:
- Manual dispatch with tag selection
- Automatic after successful CI on main branch

**Purpose**: Deploys application to production server

**Steps**:
- Validates Docker image exists in registry
- Connects to Google Cloud server via SSH
- Pulls latest image
- Replaces running container
- Configures health checks and auto-restart

## Deployment

### Required Secrets

Configure these in GitHub repository settings:

- `DEPLOY_HOST`: Google Cloud VM IP address
- `DEPLOY_USER`: SSH username for deployment
- `DEPLOY_KEY`: Private SSH key for authentication
- `DEPLOY_PORT`: SSH port (default: 22)

### Manual Deployment

1. Go to Actions tab in GitHub
2. Select "Deploy to Production" workflow
3. Click "Run workflow"
4. Enter the image tag to deploy (e.g., `latest`, `v1.0.0`, `sha-abc123`)
5. Monitor deployment progress

### Automatic Deployment

Pushes to the main branch automatically trigger:
1. CI Pipeline builds and tags the image
2. Deploy Pipeline deploys the new image to production

## Container Registry

Images are stored in GitHub Container Registry:
- URL: `ghcr.io/viksnekristians/devops_test`
- Public access for pulling
- Authenticated pushing via GitHub Actions

## Production Environment

The application runs on Google Cloud with:
- Docker container with health checks
- Auto-restart on failure
- Port 8080 exposed
- Automatic cleanup of old images

## Learning Outcomes

This project demonstrates:
- **Infrastructure as Code**: All pipelines defined in YAML
- **Continuous Integration**: Automated testing on every commit
- **Continuous Deployment**: Automated deployment to production
- **Container Best Practices**: Multi-stage builds, health checks
- **Security**: Secrets management, minimal Docker images
- **Monitoring**: Health checks and automatic recovery

## Staging Environments

### Port-Based Staging System

The project now includes a comprehensive staging environment system that allows multiple staging deployments on the same server using different ports.

#### Port Allocation:
- **Production**: Port 8080 (main branch)
- **Main Staging**: Port 9000 (develop branch)
- **Feature Staging**: Ports 9001-9099 (feature branches, dynamically assigned)

#### Automatic Deployments:
- Push to `develop` → Deploys to staging at `http://YOUR-IP:9000`
- Push to `feature/*` → Deploys to dynamic port `http://YOUR-IP:90XX`
- Pull requests → Automatic preview environment with URL in PR comment

#### Staging Workflows:

1. **Deploy to Staging** (`staging-deploy.yml`)
   - Triggered on push to develop or feature branches
   - Creates isolated Docker containers
   - Assigns consistent ports based on branch names
   - Comments on PRs with staging URLs

2. **Cleanup Staging** (`staging-cleanup.yml`)
   - Runs daily at 2 AM UTC
   - Removes staging environments older than 7 days
   - Automatically cleans up when PRs are closed
   - Manual trigger available for immediate cleanup

3. **Promote to Production** (`promote-staging.yml`)
   - Manual workflow to promote staging to production
   - Validates staging health before promotion
   - Creates deployment records
   - Maintains backup of previous production

#### Managing Staging Environments:

Use the included management script:

```bash
# List all staging environments
./scripts/manage-staging.sh list

# Check status of specific environment
./scripts/manage-staging.sh status develop
./scripts/manage-staging.sh status feature/new-feature

# View logs
./scripts/manage-staging.sh logs develop

# Check health
./scripts/manage-staging.sh health develop

# Get URL for a branch
./scripts/manage-staging.sh url feature/login

# Stop/start environments
./scripts/manage-staging.sh stop feature/test
./scripts/manage-staging.sh start feature/test

# Remove specific environment
./scripts/manage-staging.sh remove feature/old-feature

# Cleanup old environments (older than 7 days)
./scripts/manage-staging.sh cleanup 7

# Execute commands in container
./scripts/manage-staging.sh exec develop ls -la
```

#### Required GitHub Secrets:

For staging on the same server as production:
- Uses existing secrets: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY`

For separate staging server (optional):
- `STAGING_HOST`: Staging server IP
- `STAGING_USER`: SSH username
- `STAGING_KEY`: SSH private key
- `STAGING_PORT`: SSH port (default: 22)

#### Example Staging URLs:

After deployment, access your staging environments at:
- Main staging: `http://YOUR-SERVER-IP:9000`
- Feature branch: `http://YOUR-SERVER-IP:9001` (port varies by branch)

The exact URL will be displayed in:
- GitHub Actions output
- Pull request comments
- Deployment environment URL in GitHub

## Future Enhancements

- [x] Add staging environment
- [ ] Implement blue-green deployment
- [ ] Add monitoring and logging (Prometheus/Grafana)
- [ ] Kubernetes deployment option
- [ ] Database integration example
- [ ] Load balancing setup
- [ ] SSL/TLS configuration
- [ ] Add custom domain support for staging

## Contributing

This is a learning project.