# PgBouncer Multiple Instances Example

This example demonstrates how to run multiple PgBouncer instances with systemd on a single server using Docker. It's based on the EDB blog post ["Running multiple PgBouncer instances with systemd"](https://www.enterprisedb.com/blog/running-multiple-pgbouncer-instances-systemd).

## Overview

PgBouncer runs as a single process and cannot utilize multiple CPUs directly. To leverage multi-core systems, you can run multiple PgBouncer instances on the same host using systemd's socket activation feature combined with the `SO_REUSEPORT` socket option.

### Key Features

- **Multiple PgBouncer instances** running simultaneously
- **SO_REUSEPORT** enabled for load distribution across instances
- **Systemd socket activation** for managing multiple instances
- **Shared TCP port (6432)** for all instances via SO_REUSEPORT
- **Individual admin ports (50001-50004)** for monitoring each instance
- **Docker containerized** setup with systemd support

## Architecture

```
Client Applications
        │
        ├─────────┬─────────┬─────────┐
        ▼         ▼         ▼         ▼
   Instance 1  Instance 2  Instance 3  Instance 4
   (50001)     (50002)     (50003)     (50004)
        │         │         │         │
        └─────────┴────┬────┴─────────┘
                       │ (Shared port 6432 via SO_REUSEPORT)
                       ▼
                  PostgreSQL Database
```

## How It Works

1. **SO_REUSEPORT**: Multiple PgBouncer processes can bind to the same TCP port (6432). The kernel distributes incoming connections across all instances.

2. **Systemd Socket Activation**: Systemd creates and manages the listen sockets, then passes them to PgBouncer instances when they start.

3. **Template Units**: Systemd template units (`pgbouncer@.service` and `pgbouncer@.socket`) allow easy instantiation of multiple instances using identifiers (50001, 50002, etc.).

4. **Per-Instance Admin Ports**: Each instance gets its own admin port for monitoring and management without interfering with production traffic.

## Directory Structure

```
multiple_instances_example/
├── Dockerfile                      # Container with systemd and PgBouncer
├── docker-compose.yml              # Service orchestration
├── Makefile                        # Convenient command shortcuts
├── README.md                       # This file
└── config/
    ├── pgbouncer.ini               # PgBouncer configuration
    ├── userlist.txt                # User authentication
    ├── pgbouncer@.socket           # Systemd socket unit template
    └── pgbouncer@.service          # Systemd service unit template
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

Or without Make:

```bash
docker-compose build
docker-compose up -d
```

### 2. Check Status

```bash
make status
```

This shows the systemd status of all four PgBouncer instances.

### 3. Test Connection

Test the main production port:

```bash
make test-connection
```

Test admin connections to each instance:

```bash
make test-admin
```

## Configuration Files

### pgbouncer.ini

Main PgBouncer configuration with `so_reuseport = 1` enabled. This setting is crucial for allowing multiple instances to share port 6432.

Key settings:
- `so_reuseport = 1` - Enable SO_REUSEPORT socket option
- `pool_mode = transaction` - Connection pooling mode
- `max_client_conn = 100` - Maximum client connections per instance
- `default_pool_size = 20` - Default pool size per database/user pair

### pgbouncer@.socket

Systemd socket unit template that creates:
- One TCP socket on port 6432 (shared by all instances)
- One TCP socket on port %i (per-instance admin port)
- One Unix socket at /tmp/.s.PGSQL.%i (per-instance)

The `%i` is replaced with the instance identifier (50001, 50002, etc.).

### pgbouncer@.service

Systemd service unit template that:
- Depends on the corresponding socket unit
- Runs PgBouncer as the postgres user
- Supports configuration reload with SIGHUP
- Automatically restarts on failure

## Available Make Targets

```bash
make help              # Show all available commands
make build             # Build Docker images
make up                # Start all services
make down              # Stop all services
make logs              # Show logs from all services
make logs-pgbouncer    # Show PgBouncer container logs
make logs-postgres     # Show PostgreSQL container logs
make status            # Show status of all PgBouncer instances
make test-connection   # Test connection via main port
make test-admin        # Test admin connections to each instance
make restart           # Restart all services
make clean             # Remove everything (containers, volumes, images)
make ps                # Show processes inside PgBouncer container
make shell             # Open shell in PgBouncer container
make shell-postgres    # Open shell in PostgreSQL container
```

## Manual Commands

### Check PgBouncer Instances

```bash
# Inside the container
docker exec pgbouncer_multi systemctl status pgbouncer@50001
docker exec pgbouncer_multi systemctl status pgbouncer@50002
docker exec pgbouncer_multi systemctl status pgbouncer@50003
docker exec pgbouncer_multi systemctl status pgbouncer@50004
```

### Connect to PgBouncer Admin Console

```bash
# Via main port (connects to any instance)
docker exec -it pgbouncer_multi psql -h localhost -p 6432 -U pgbouncer -d pgbouncer

# Via specific instance admin port
docker exec -it pgbouncer_multi psql -h localhost -p 50001 -U pgbouncer -d pgbouncer
```

### Useful PgBouncer Admin Commands

```sql
SHOW POOLS;          -- Show all connection pools
SHOW CLIENTS;        -- Show client connections
SHOW SERVERS;        -- Show server connections
SHOW STATS;          -- Show statistics
RELOAD;              -- Reload configuration
SHOW CONFIG;         -- Show configuration
```

## How to Scale

To add more instances:

1. Edit the Dockerfile to enable additional socket units:
```dockerfile
RUN systemctl enable pgbouncer@50005.socket && \
    systemctl enable pgbouncer@50006.socket
```

2. Update docker-compose.yml to expose the new ports:
```yaml
ports:
  - "50005:50005"
  - "50006:50006"
```

3. Rebuild and restart:
```bash
make clean
make build
make up
```

## Monitoring

Each instance can be monitored independently via its admin port:

```bash
# Check pools for instance 50001
docker exec pgbouncer_multi psql -h localhost -p 50001 -U pgbouncer -d pgbouncer -c "SHOW POOLS;"

# Check stats for instance 50002
docker exec pgbouncer_multi psql -h localhost -p 50002 -U pgbouncer -d pgbouncer -c "SHOW STATS;"
```

## Troubleshooting

### DNS Resolution Errors During Build

If you see errors like `Temporary failure resolving 'deb.debian.org'` during `docker build`:

**Quick Fix - Build with Host Network:**
```bash
docker build --network=host -t multiple_instances_example-pgbouncer .
docker-compose up -d
```

**Permanent Fix - Configure Docker Daemon DNS:**

1. Edit Docker daemon configuration:
```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

2. Add or merge this content:
```json
{
  "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
}
```

3. Restart Docker:
```bash
sudo systemctl restart docker
```

4. Try building again:
```bash
make build
```

**Verify Host DNS:**
```bash
cat /etc/resolv.conf
nslookup deb.debian.org
```

If your host system cannot resolve DNS, fix that first. Docker inherits DNS settings from the host system.

**Note:** The `dns` setting in docker-compose.yml only applies to running containers, not the build process. That's why you need to configure the Docker daemon for build-time DNS resolution.

### Instances Not Starting

Check systemd journal logs:
```bash
docker exec pgbouncer_multi journalctl -u pgbouncer@50001 -f
```

### Socket Issues

Verify sockets are created:
```bash
docker exec pgbouncer_multi systemctl list-sockets | grep pgbouncer
```

### Connection Refused

1. Ensure PostgreSQL is healthy:
```bash
docker exec pgbouncer_postgres pg_isready -U postgres
```

2. Check PgBouncer logs:
```bash
make logs-pgbouncer
```

3. Verify network connectivity:
```bash
docker exec pgbouncer_multi ping postgres
```

### Package Installation Errors

If you see errors like `E: Unable to locate package pgbouncer`:

1. The Dockerfile is configured to add the PostgreSQL APT repository which contains pgbouncer
2. Ensure the repository addition steps complete successfully in the build output
3. If behind a corporate proxy, you may need to configure Docker to use it:
```bash
# Add to /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:80"
Environment="HTTPS_PROXY=http://proxy.example.com:80"
Environment="NO_PROXY=localhost,127.0.0.1"
```

## Performance Considerations

- **CPU Utilization**: Each instance runs on a separate process, allowing better CPU utilization on multi-core systems.
- **Load Distribution**: The kernel's SO_REUSEPORT implementation distributes connections roughly equally across instances.
- **Connection Limits**: Each instance has its own connection pool limits. Total capacity = instances × pool_size.
- **Memory**: Each instance consumes additional memory. Monitor memory usage and adjust the number of instances accordingly.

## Security Notes

1. **Privileged Mode**: The container runs in privileged mode to support systemd. In production, consider using a more restricted setup.
2. **User Authentication**: Update `userlist.txt` with proper password hashes. Use `md5` or preferably `scram-sha-256`.
3. **Network Security**: Configure firewall rules to restrict access to admin ports (50001-50004) to authorized hosts only.

## References

- [EDB Blog: Running multiple PgBouncer instances with systemd](https://www.enterprisedb.com/blog/running-multiple-pgbouncer-instances-systemd)
- [PgBouncer Documentation](https://www.pgbouncer.org/usage.html)
- [SO_REUSEPORT Documentation](https://lwn.net/Articles/542629/)
- [systemd.socket Documentation](https://www.freedesktop.org/software/systemd/man/systemd.socket.html)

## License

This example is provided for educational purposes.

## Life Testing and Real-Time Monitoring

A Python script `life_test.py` is included to demonstrate the load balancing capabilities in real-time.

### Prerequisites

- Python 3
- `pip`

### Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Ensure the environment is running:
   ```bash
   make up
   ```

### Running the Test

Run the life test script:

```bash
python3 life_test.py
```

### What to Expect

1. **Database Initialization**: The script will automatically create a `usage_logs` table in the `testdb` database if it doesn't exist.
2. **Traffic Generation**: 20 concurrent client threads will start performing random `INSERT`, `UPDATE`, and `SELECT` operations via the main PgBouncer port (6432).
3. **Real-Time Dashboard**: A terminal dashboard will appear, showing:
   - The status of each PgBouncer instance (50001-50004).
   - The number of active client connections handled by each instance.
   
You should see the client connections roughly balanced across the four instances, demonstrating the `SO_REUSEPORT` functionality.
