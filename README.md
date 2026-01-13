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

## Future Enhancements

- [ ] Add staging environment
- [ ] Implement blue-green deployment
- [ ] Add monitoring and logging (Prometheus/Grafana)
- [ ] Kubernetes deployment option
- [ ] Database integration example
- [ ] Load balancing setup
- [ ] SSL/TLS configuration

## Contributing

This is a learning project.