# PgBouncer Multi-Port Example

This example demonstrates how a **single PgBouncer instance** can listen on **multiple ports** using systemd socket activation.

## Use Case

Useful when consolidating multiple PostgreSQL instances or PgBouncer instances into one, but client applications are hardcoded to talk to different ports (e.g., 6432, 6433, 6434).

## Mechanism

We use `systemd-socket-activate` (part of systemd) to bind multiple ports and pass their file descriptors to the PgBouncer process. PgBouncer automatically detects and uses these passed sockets.

## Configuration

**Dockerfile**:
```dockerfile
CMD ["/lib/systemd/systemd-socket-activate", "-l", "6432", "-l", "6433", "-l", "6434", "/usr/sbin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
```

**PgBouncer Config**:
Standard configuration using `listen_addr = *`. The ports are inherited from systemd.

## How to Run

1. **Start Services**:
   ```bash
   make build
   make up
   ```

2. **Visual Verification (Life Test)**:
   ```bash
   make life-test
   ```
   This dashboard connects randomly to ports 6432, 6433, and 6434, showing that a single PgBouncer instance is handling traffic on all of them.

   ![Multi-Port Dashboard](assets/multi_port_dashboard.png)
