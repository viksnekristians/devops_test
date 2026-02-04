#!/bin/bash
set -e

echo "Setting up MySQL replication..."

# Wait for MySQL services to be ready
sleep 10

# Get master status
MASTER_STATUS=$(docker exec prod-db mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G")
MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

echo "Master log file: $MASTER_LOG_FILE"
echo "Master log position: $MASTER_LOG_POS"

# Configure replica
docker exec prod-db-replica mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='prod-db',
  MASTER_USER='replicator',
  MASTER_PASSWORD='${REPLICATION_PASSWORD}',
  MASTER_LOG_FILE='${MASTER_LOG_FILE}',
  MASTER_LOG_POS=${MASTER_LOG_POS};
START SLAVE;
"

# Check replication status
sleep 5
docker exec prod-db-replica mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"

echo "Replication setup complete!"