-- Create replication user (only execute on master)
-- This script will be executed on both master and replica during init
-- But the replica will be read-only so these statements will fail safely there

-- Create replication user
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY '${REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;