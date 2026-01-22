# PgBouncer Connection Capping Example

This example demonstrates how to use PgBouncer to limit database connections per user and per database, preventing any single user or database from exhausting all available connections.

## Overview

PgBouncer provides three key parameters for capping connections:

1. **`max_db_connections`** - Limits server connections per database
2. **`max_user_connections`** - Limits server connections per user (across all databases)
3. **`max_client_conn`** - Limits total client connections to PgBouncer

These limits work together to provide fair resource allocation and prevent connection exhaustion.

## Configuration

### Connection Limits in pgbouncer.ini

```ini
# Maximum server connections per database (5)
max_db_connections = 5

# Maximum server connections per user across all databases (3)
max_user_connections = 3

# Maximum total client connections to PgBouncer (100)
max_client_conn = 100

# Default pool size per user/database pair (10)
default_pool_size = 10
```

### How Limits Work

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                   │
└────────────┬─────────────────────┬──────────────────────┘
             │                     │
             │ max_client_conn     │ (Total: 100)
             │                     │
        ┌────▼─────────────────────▼────┐
        │         PgBouncer              │
        │                                │
        │  User Limits:                  │
        │  • user1: max 3 connections    │ ◄── max_user_connections
        │  • user2: max 3 connections    │
        │                                │
        │  Database Limits:              │
        │  • testdb1: max 5 connections  │ ◄── max_db_connections
        │  • testdb2: max 5 connections  │
        └────────────────┬───────────────┘
                         │
                    ┌────▼────┐
                    │  Postgres│
                    └─────────┘
```

## Directory Structure

```
capping_user_connections/
├── Dockerfile                  # PgBouncer container
├── docker-compose.yml          # Service orchestration
├── Makefile                    # Convenient commands
├── README.md                   # This file
├── config/
│   ├── pgbouncer.ini          # PgBouncer configuration with limits
│   ├── userlist.txt           # User authentication
│   └── init-db.sql            # Database initialization
└── scripts/
    ├── test_user_limit.sh     # Test user connection limits
    ├── test_db_limit.sh       # Test database connection limits
    └── demo_all.sh            # Complete demonstration
```

## Prerequisites

- Docker
- Docker Compose
- Make (optional, for using Makefile commands)

## Quick Start

### 1. Build and Start Services

```bash
make build
make up
```

**If you encounter DNS resolution errors during build:**
```bash
make build-host
docker-compose up -d
```

### 2. Run the Demonstration

```bash
make demo
```

This runs a comprehensive demonstration showing:
- How `max_user_connections` prevents a user from opening more than 3 connections
- How `max_db_connections` limits connections to a single database
- Current pool status and statistics

### 3. Run Individual Tests

Test user connection limits:
```bash
make test-user-limit
```

Test database connection limits:
```bash
make test-db-limit
```

### 4. Check Status

View current connection pools:
```bash
make status
```

View configuration:
```bash
make config
```

View statistics:
```bash
make stats
```

## Understanding the Limits

### max_user_connections

**Purpose:** Prevents a single user from monopolizing connections across all databases.

**Example:**
- User1 opens 2 connections to testdb1
- User1 opens 1 connection to testdb2
- Total: 3 connections (limit reached)
- User1 attempts 4th connection → **REJECTED or QUEUED**

**Test it:**
```bash
make test-user-limit
```

### max_db_connections

**Purpose:** Protects individual databases from connection overload.

**Example:**
- User1 opens 2 connections to testdb1
- User2 opens 2 connections to testdb1
- User3 opens 1 connection to testdb1
- Total: 5 connections to testdb1 (limit reached)
- Any user attempts another connection to testdb1 → **REJECTED or QUEUED**
- Connections to testdb2 still work normally

**Test it:**
```bash
make test-db-limit
```

### max_client_conn

**Purpose:** Limits total client connections to PgBouncer itself.

**Note:** This is different from server connections. PgBouncer can accept many client connections but only maintains a limited number of actual server connections to PostgreSQL.

## Available Make Targets

```bash
make help               # Show all available commands
make build              # Build Docker images
make build-host         # Build with host network (DNS workaround)
make up                 # Start all services
make down               # Stop all services
make logs               # Show all logs
make logs-pgbouncer     # Show PgBouncer logs
make logs-postgres      # Show PostgreSQL logs
make status             # Show pool status
make config             # Show configuration
make stats              # Show statistics
make databases          # Show configured databases
make demo               # Run complete demonstration
make test-user-limit    # Test user connection limits
make test-db-limit      # Test database connection limits
make test               # Run all tests
make restart            # Restart services
make clean              # Clean up everything
make shell              # Open shell in PgBouncer container
make shell-postgres     # Open shell in PostgreSQL container
make psql-admin         # Connect to PgBouncer admin console
make psql-user1         # Connect as user1 via PgBouncer
make psql-direct        # Connect directly to PostgreSQL
make pg-connections     # Show PostgreSQL active connections
```

## Manual Testing

### Connect to PgBouncer Admin Console

```bash
docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer
```

### Useful Admin Commands

```sql
-- View all connection pools
SHOW POOLS;

-- View statistics
SHOW STATS;

-- View configuration
SHOW CONFIG;

-- View configured databases
SHOW DATABASES;

-- View client connections
SHOW CLIENTS;

-- View server connections
SHOW SERVERS;

-- Reload configuration
RELOAD;
```

### Test Connection Limits Manually

**Terminal 1 - Open connections as user1:**
```bash
# Connection 1
docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U user1 -d testdb1

# Connection 2 (open in another terminal)
docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U user1 -d testdb1

# Connection 3
docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U user1 -d testdb2

# Connection 4 - should be rejected or queued
docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U user1 -d testdb2
```

**Terminal 2 - Monitor pools:**
```bash
make status
```

## Configuration Details

### Users

| Username | Password   | Purpose                          |
|----------|------------|----------------------------------|
| admin    | admin123   | PgBouncer admin access           |
| monitor  | monitor    | Read-only stats access           |
| user1    | user1      | Test user (limited to 3 conns)   |
| user2    | user2      | Test user (limited to 3 conns)   |
| user3    | user3      | Test user (limited to 3 conns)   |

### Databases

| Database | Purpose                    |
|----------|----------------------------|
| postgres | Default database           |
| testdb1  | Test database 1            |
| testdb2  | Test database 2            |

## Troubleshooting

### DNS Resolution Errors During Build

If you see `Temporary failure resolving 'deb.debian.org'`:

```bash
make build-host
docker-compose up -d
```

Or configure Docker daemon DNS (permanent fix):
```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

Then:
```bash
sudo systemctl restart docker
make build
```

### Connection Rejected Immediately

If connections are rejected immediately rather than queued:
1. Check pool size: `make config`
2. Increase `reserve_pool_size` if needed
3. Consider using `pool_mode = transaction` for better connection reuse

### Cannot Connect to PgBouncer

1. Check if services are running:
   ```bash
   docker-compose ps
   ```

2. Check PgBouncer logs:
   ```bash
   make logs-pgbouncer
   ```

3. Verify PostgreSQL is healthy:
   ```bash
   docker exec pgbouncer_postgres_cap pg_isready -U postgres
   ```

### Pools Showing 0 Connections

This is normal when no queries are active. PgBouncer only maintains server connections when needed. Use the test scripts to generate activity:
```bash
make demo
```

## Use Cases

### 1. Multi-Tenant Applications

Each tenant gets their own user with `max_user_connections` ensuring fair resource allocation:
```ini
max_user_connections = 5  # Each tenant limited to 5 connections
```

### 2. Microservices Architecture

Prevent any single microservice from exhausting database connections:
```ini
max_user_connections = 10  # Per microservice user limit
max_db_connections = 50    # Per database limit
```

### 3. Development/Testing Environments

Protect shared databases in development:
```ini
max_user_connections = 3   # Prevent developers from leaving connections open
max_db_connections = 20    # Protect each database
```

### 4. Connection Storm Protection

During traffic spikes or application restarts:
```ini
max_client_conn = 1000     # Accept many clients
max_db_connections = 50    # But limit actual database connections
reserve_pool_size = 10     # Emergency reserve
```

## Performance Considerations

- **Pool Mode**: Use `transaction` mode for better connection reuse if possible
- **Pool Size**: Set `default_pool_size` based on expected concurrent queries per database
- **Reserve Pool**: Keep `reserve_pool_size` for handling bursts
- **Monitoring**: Regularly check `SHOW STATS` to tune limits appropriately

## Best Practices

1. **Set Realistic Limits**: Base limits on actual database capacity and expected load
2. **Monitor Regularly**: Use `SHOW POOLS` and `SHOW STATS` to track usage
3. **Use Reserve Pools**: Always configure `reserve_pool_size` for spikes
4. **Test Limits**: Verify limits work as expected under load
5. **Document Users**: Clearly document which applications use which users
6. **Log Analysis**: Monitor `log_connections` and `log_disconnections` for troubleshooting

## Security Notes

1. **Change Default Passwords**: Update all passwords in `userlist.txt` and `init-db.sql`
2. **Use Strong Hashes**: Consider using `scram-sha-256` instead of `md5`
3. **Restrict Admin Access**: Limit who can access the admin console
4. **Network Security**: Use firewall rules to restrict PgBouncer port access
5. **Connection Limits**: Properly configured limits are part of DoS protection

## References

- [PgBouncer Documentation](https://www.pgbouncer.org/usage.html)
- [PgBouncer Configuration](https://www.pgbouncer.org/config.html)
- [Connection Pooling Best Practices](https://www.percona.com/blog/pgbouncer-for-postgresql-how-connection-pooling-solves-enterprise-slowdowns/)

## License

This example is provided for educational purposes.
