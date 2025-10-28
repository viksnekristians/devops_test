# GitHub Actions Pipelines

This repository includes three GitHub Actions workflows:

## 1. CI Pipeline (`ci.yml`)

Triggers on:
- Push to `main` or `develop` branches
- Pull requests to `main`

Features:
- **Multi-version PHP testing** (8.0, 8.1, 8.2)
- **Dependency caching** for faster builds
- **PHPUnit test execution**
- **Code coverage reporting** to Codecov
- **Docker image building** and pushing to Docker Hub
- **Security scanning** with Trivy

### Required Secrets:
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_TOKEN`: Docker Hub access token

## 2. Deploy Pipeline (`deploy.yml`)

Triggers on:
- Git tags (v*)
- Manual workflow dispatch

Features:
- **Builds and pushes** to GitHub Container Registry
- **Automatic deployment** via SSH to production server
- **Semantic versioning** support

### Required Secrets:
- `DEPLOY_HOST`: Production server hostname/IP
- `DEPLOY_USER`: SSH username
- `DEPLOY_KEY`: SSH private key
- `DEPLOY_PORT`: SSH port (optional, defaults to 22)

## 3. PR Checks (`pr-checks.yml`)

Triggers on:
- Pull request events

Features:
- **Code style checking** (PSR-12)
- **Static analysis** with PHPStan
- **Merge conflict detection**
- **Docker image size monitoring**

## Setup Instructions

1. **Enable GitHub Actions** in your repository settings

2. **Configure Secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Add required secrets listed above

3. **Docker Hub Setup** (for CI pipeline):
   - Create access token at https://hub.docker.com/settings/security
   - Add as `DOCKER_TOKEN` secret

4. **Codecov Setup** (optional):
   - Sign up at https://codecov.io
   - Add repository
   - Badge will appear in PRs automatically

5. **Deployment Setup**:
   - Generate SSH key pair for deployment
   - Add public key to production server
   - Add private key as `DEPLOY_KEY` secret

## Usage

- **Regular commits** trigger CI pipeline
- **Create tags** for production deployments: `git tag v1.0.0 && git push --tags`
- **Pull requests** automatically run all checks
- **Manual deployment**: Go to Actions → Deploy to Production → Run workflow

## Customization

Modify workflows as needed:
- Add more PHP versions in test matrix
- Change deployment strategy
- Add additional security scanners
- Configure different Docker registries