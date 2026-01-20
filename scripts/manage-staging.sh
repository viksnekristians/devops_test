#!/bin/bash

# Staging Environment Management Script
# This script helps manage staging environments locally or on the server

set -e

# Configuration
REGISTRY="ghcr.io/viksnekristians/devops_test"
DEFAULT_HOST=${STAGING_HOST:-localhost}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list                    List all staging environments"
    echo "  status <branch>         Show status of specific staging environment"
    echo "  logs <branch>           Show logs for staging environment"
    echo "  stop <branch>           Stop a staging environment"
    echo "  start <branch>          Start a stopped staging environment"
    echo "  remove <branch>         Remove a staging environment"
    echo "  cleanup [days]          Remove staging environments older than X days (default: 7)"
    echo "  port <branch>           Get the port for a branch"
    echo "  url <branch>            Get the URL for a staging environment"
    echo "  health <branch>         Check health of staging environment"
    echo "  exec <branch> <cmd>     Execute command in staging container"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 status develop"
    echo "  $0 logs feature/new-feature"
    echo "  $0 cleanup 14"
    echo "  $0 health develop"
    exit 1
}

# Function to get container name from branch
get_container_name() {
    local branch=$1
    if [[ "${branch}" == "develop" ]]; then
        echo "staging-main"
    else
        local safe_branch=$(echo "${branch}" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
        echo "staging-${safe_branch}"
    fi
}

# Function to get port from branch
get_port() {
    local branch=$1
    if [[ "${branch}" == "develop" ]]; then
        echo "9000"
    else
        local hash=$(echo -n "${branch}" | md5sum | cut -c1-8)
        local port_offset=$((0x${hash} % 99))
        echo $((9001 + ${port_offset}))
    fi
}

# List all staging environments
list_staging() {
    echo -e "${BLUE}📋 Staging Environments:${NC}"
    echo ""

    # Check staging deployments directory
    if [[ -d "$HOME/staging-deployments" ]]; then
        for dir in $HOME/staging-deployments/*/; do
            if [[ -f "${dir}docker-compose.yml" ]]; then
                DEPLOY_NAME=$(basename "$dir")
                echo -e "\n${YELLOW}${DEPLOY_NAME}:${NC}"
                cd "$dir"
                docker-compose ps 2>/dev/null || echo "  Not running"
            fi
        done
    else
        echo -e "${YELLOW}No staging environments found${NC}"
    fi

    echo ""
    echo -e "${GREEN}Production:${NC}"
    if [[ -f "$HOME/production/docker-compose.yml" ]]; then
        cd $HOME/production
        docker-compose ps 2>/dev/null || echo "Not running"
    else
        echo "Not deployed"
    fi
}

# Show status of specific staging
status_staging() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local port=$(get_port "$branch")
    local deploy_dir="$HOME/staging-deployments/${container_name}"

    echo -e "${BLUE}📊 Status for branch: ${branch}${NC}"
    echo "Container: ${container_name}"
    echo "Port: ${port}"
    echo "URL: http://${DEFAULT_HOST}:${port}"
    echo ""

    if [[ -d "${deploy_dir}" && -f "${deploy_dir}/docker-compose.yml" ]]; then
        cd "${deploy_dir}"
        docker-compose ps

        # Check health status
        if docker-compose ps | grep -q "healthy"; then
            echo -e "\n${GREEN}🏥 Healthy${NC}"
        elif docker-compose ps | grep -q "starting"; then
            echo -e "\n${YELLOW}⚠️  Starting up...${NC}"
        else
            echo -e "\n${YELLOW}⚠️  Not healthy${NC}"
        fi
    else
        echo -e "${RED}❌ Not deployed${NC}"
    fi
}

# Show logs
show_logs() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local deploy_dir="$HOME/staging-deployments/${container_name}"

    if [[ -d "${deploy_dir}" && -f "${deploy_dir}/docker-compose.yml" ]]; then
        cd "${deploy_dir}"
        echo -e "${BLUE}📜 Logs for ${container_name}:${NC}"
        docker-compose logs --tail 50 -f
    else
        echo -e "${RED}Deployment not found${NC}"
    fi
}

# Stop staging environment
stop_staging() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local deploy_dir="$HOME/staging-deployments/${container_name}"

    if [[ -d "${deploy_dir}" && -f "${deploy_dir}/docker-compose.yml" ]]; then
        cd "${deploy_dir}"
        echo -e "${YELLOW}⏹️  Stopping ${container_name}...${NC}"
        docker-compose stop && echo -e "${GREEN}✅ Stopped${NC}" || echo -e "${RED}❌ Failed to stop${NC}"
    else
        echo -e "${RED}Deployment not found${NC}"
    fi
}

# Start staging environment
start_staging() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local deploy_dir="$HOME/staging-deployments/${container_name}"

    if [[ -d "${deploy_dir}" && -f "${deploy_dir}/docker-compose.yml" ]]; then
        cd "${deploy_dir}"
        echo -e "${GREEN}▶️  Starting ${container_name}...${NC}"
        docker-compose start && echo -e "${GREEN}✅ Started${NC}" || echo -e "${RED}❌ Failed to start${NC}"
    else
        echo -e "${RED}Deployment not found${NC}"
    fi
}

# Remove staging environment
remove_staging() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local deploy_dir="$HOME/staging-deployments/${container_name}"

    echo -e "${RED}🗑️  Removing ${container_name}...${NC}"

    if [[ -d "${deploy_dir}" && -f "${deploy_dir}/docker-compose.yml" ]]; then
        cd "${deploy_dir}"
        # Stop and remove containers and volumes
        docker-compose down --volumes
        echo -e "${GREEN}✅ Removed containers and volumes${NC}"

        # Remove deployment directory
        cd ~
        rm -rf "${deploy_dir}"
        echo -e "${GREEN}✅ Removed deployment directory${NC}"
    else
        echo -e "${YELLOW}Deployment not found${NC}"
    fi

    # Remove port tracking file if exists
    local port=$(get_port "$branch")
    if [[ -f "$HOME/staging-ports/port-${port}.txt" ]]; then
        rm -f "$HOME/staging-ports/port-${port}.txt"
    fi
}

# Cleanup old environments
cleanup_old() {
    local days=${1:-7}

    echo -e "${BLUE}🧹 Cleaning up staging environments older than ${days} days...${NC}"

    local cutoff_date=$(date -d "${days} days ago" +%s)

    docker ps -a --filter "label=staging=true" --format "{{.Names}}\t{{.Label \"deployed\"}}\t{{.Label \"branch\"}}" | while IFS=$'\t' read -r name deployed branch; do
        # Skip develop branch
        if [[ "${branch}" == "develop" ]]; then
            echo -e "${YELLOW}Keeping main staging: ${name}${NC}"
            continue
        fi

        # Check age
        if [[ -n "${deployed}" && "${deployed}" != "<no" ]]; then
            deployed_ts=$(date -d "${deployed}" +%s 2>/dev/null || echo "0")
            if [[ ${deployed_ts} -lt ${cutoff_date} ]]; then
                echo -e "${RED}Removing old container: ${name} (${branch})${NC}"
                docker stop ${name} 2>/dev/null || true
                docker rm ${name} 2>/dev/null || true
            else
                echo -e "${GREEN}Keeping recent: ${name} (${branch})${NC}"
            fi
        fi
    done

    # Clean up unused images
    echo -e "${BLUE}Cleaning up unused images...${NC}"
    docker image prune -af --filter "until=${days}d"
}

# Get URL for staging
get_url() {
    local branch=$1
    local port=$(get_port "$branch")
    echo "http://${DEFAULT_HOST}:${port}"
}

# Check health
check_health() {
    local branch=$1
    local container_name=$(get_container_name "$branch")
    local port=$(get_port "$branch")
    local url="http://${DEFAULT_HOST}:${port}"

    echo -e "${BLUE}🏥 Checking health for ${branch}...${NC}"
    echo "Container: ${container_name}"
    echo "URL: ${url}"
    echo ""

    # Check if container is running
    if ! docker ps --filter "name=${container_name}" --format "{{.Names}}" | grep -q "${container_name}"; then
        echo -e "${RED}❌ Container not running${NC}"
        exit 1
    fi

    # Check container health status
    if docker ps --filter "name=${container_name}" --filter "health=healthy" --format "{{.Names}}" | grep -q "${container_name}"; then
        echo -e "${GREEN}✅ Container health: HEALTHY${NC}"
    else
        echo -e "${YELLOW}⚠️  Container health: NOT HEALTHY${NC}"
    fi

    # Try to curl the endpoint
    echo ""
    echo "Testing HTTP endpoint..."
    if curl -f -s -o /dev/null -w "HTTP Status: %{http_code}\n" ${url}; then
        echo -e "${GREEN}✅ Endpoint responding${NC}"
    else
        echo -e "${RED}❌ Endpoint not responding${NC}"
        exit 1
    fi
}

# Execute command in container
exec_in_staging() {
    local branch=$1
    shift
    local cmd="$@"
    local container_name=$(get_container_name "$branch")

    echo -e "${BLUE}🔧 Executing in ${container_name}: ${cmd}${NC}"
    docker exec -it ${container_name} ${cmd}
}

# Main script logic
if [[ $# -eq 0 ]]; then
    usage
fi

command=$1
shift

case ${command} in
    list)
        list_staging
        ;;
    status)
        [[ $# -eq 0 ]] && usage
        status_staging "$1"
        ;;
    logs)
        [[ $# -eq 0 ]] && usage
        show_logs "$1"
        ;;
    stop)
        [[ $# -eq 0 ]] && usage
        stop_staging "$1"
        ;;
    start)
        [[ $# -eq 0 ]] && usage
        start_staging "$1"
        ;;
    remove)
        [[ $# -eq 0 ]] && usage
        remove_staging "$1"
        ;;
    cleanup)
        cleanup_old "$1"
        ;;
    port)
        [[ $# -eq 0 ]] && usage
        get_port "$1"
        ;;
    url)
        [[ $# -eq 0 ]] && usage
        get_url "$1"
        ;;
    health)
        [[ $# -eq 0 ]] && usage
        check_health "$1"
        ;;
    exec)
        [[ $# -eq 0 ]] && usage
        branch=$1
        shift
        exec_in_staging "${branch}" "$@"
        ;;
    *)
        echo -e "${RED}Unknown command: ${command}${NC}"
        usage
        ;;
esac