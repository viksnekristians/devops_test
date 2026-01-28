# MySQL Read Replica Setup for Production

## Overview
This setup adds a MySQL read replica to the production environment for improved read performance and availability.

## Architecture
- **Primary Database (prod-db)**: Handles all write operations
- **Read Replica (prod-db-replica)**: Handles read-only queries
- **Application**: Routes reads to replica, writes to primary

## Setup Instructions

### 1. Deploy the Updated Configuration
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Initialize Replication
After both databases are running, execute the replication setup:

```bash
# Set environment variables
export MYSQL_ROOT_PASSWORD=your_root_password
export REPLICATION_PASSWORD=your_replication_password

# Run the setup script
./docker/mysql/setup-replication.sh
```

### 3. Verify Replication Status
Check that replication is working:

```bash
docker exec prod-db-replica mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"
```

Expected output:
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
```

## Environment Variables

Required environment variables for production:

- `DB_HOST`: Primary database host (default: prod-db)
- `DB_READ_HOST`: Read replica host (default: prod-db-replica)
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password
- `MYSQL_ROOT_PASSWORD`: Root password for MySQL
- `REPLICATION_PASSWORD`: Password for replication user

## Monitoring

The application displays replication status at the root URL, showing:
- Whether read replica is configured
- Replication running status
- Replication lag in seconds

## Troubleshooting

### Replication Not Starting
1. Check master status:
   ```bash
   docker exec prod-db mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"
   ```

2. Check slave status:
   ```bash
   docker exec prod-db-replica mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"
   ```

3. Reset replication if needed:
   ```bash
   docker exec prod-db-replica mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "STOP SLAVE; RESET SLAVE ALL;"
   ```
   Then re-run the setup script.

### High Replication Lag
- Monitor `Seconds_Behind_Master` value
- Consider increasing replica resources if lag is consistent
- Check network connectivity between containers

## Rollback Plan

To disable read replica and revert to single database:
1. Update `DB_READ_HOST` to match `DB_HOST` in environment variables
2. Restart the application container
3. Optionally remove the replica container:
   ```bash
   docker-compose -f docker-compose.prod.yml stop db-replica
   docker-compose -f docker-compose.prod.yml rm db-replica
   ```

## Security Notes
- Read replica is configured as read-only (`read_only=1`, `super_read_only=1`)
- Replication user has minimal privileges (only REPLICATION SLAVE)
- All database connections use encrypted passwords from environment variables