#!/bin/bash
# Emergency fix for production database tables

echo "Creating tables in production database..."

# Connect to production database and create tables
docker exec prod-db mysql -uroot -p${MYSQL_ROOT_PASSWORD} production_db <<'EOF'
-- Initialize database schema
CREATE TABLE IF NOT EXISTS app_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50),
    environment VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
INSERT INTO app_info (version, environment) VALUES ('1.0.0', 'production');

-- Create health check table
CREATE TABLE IF NOT EXISTS health_check (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(20),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO health_check (status) VALUES ('healthy');

-- Create replication user
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY '${REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
EOF

echo "Tables created successfully!"
echo "Now run ./docker/mysql/setup-replication.sh to set up replication"