#!/bin/bash

echo "Building Docker image..."
docker-compose build

echo "Running tests inside Docker container..."
docker-compose run --rm php-app vendor/bin/phpunit tests

echo "Tests completed!"