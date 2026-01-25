# Dedicated PgBouncer per Tenant/Team Example

This example demonstrates how to deploy **Dedicated PgBouncer instances per Tenant/Team**, ensuring complete isolation of authentication, configuration, and workloads.

## Use Case

High-compliance environments or multi-tenant SaaS platforms often require strict isolation between tenants. Sharing a single PgBouncer instance can lead to:
- **"Noisy Neighbor" issues**: One tenant exhausting the global connection pool.
- **Complex Configuration**: Giant `pgbouncer.ini` and `userlist.txt` files that are hard to manage.
- **Security Risks**: Shared authentication files where a mistake could expose one tenant's credentials to another.

By running a dedicated PgBouncer setup for each tenant:
1.  **Isolation**: Each tenant acts as if they have their own database proxy.
2.  **Resource Limiting**: Limits (`max_client_conn`, `default_pool_size`) are applied strictly per tenant.
3.  **Simplified Management**: Each tenant has their own config files.
4.  **Simplified `pg_hba.conf`**: The main database only needs to trust the PgBouncer instances (e.g., via localhost or a subnet), while PgBouncer handles the fine-grained user authentication.

## Architecture

We use **Systemd Template Units** to manage multiple PgBouncer processes efficiently on a single server (or container).

- `pgbouncer@tenant_a.service` -> Reads `/etc/pgbouncer/pgbouncer_tenant_a.ini` -> Listens on Port 6432
- `pgbouncer@tenant_b.service` -> Reads `/etc/pgbouncer/pgbouncer_tenant_b.ini` -> Listens on Port 6433

## Files

- `config/pgbouncer@.service`: The systemd template.
- `config/pgbouncer_tenant_a.ini`: Config for Tenant A (Port 6432).
- `config/userlist_tenant_a.txt`: Users for Tenant A.
- `config/pgbouncer_tenant_b.ini`: Config for Tenant B (Port 6433).
- `config/userlist_tenant_b.txt`: Users for Tenant B.

## Usage

### 1. Build and Start

```bash
make build
make up
```

### 2. Verify Status

Check that both independent processes are running:

```bash
make status
```

### 3. Test Connectivity

Verify that Tenant A can connect on port 6432 and Tenant B on port 6433.

```bash
make test
```

### 4. Demonstrating Isolation

- **Tenant A** connects to `localhost:6432` using `user_a`.
- **Tenant B** connects to `localhost:6433` using `user_b`.
- Tenant A cannot authenticate on Tenant B's port (credentials are in a different file).
- If Tenant A exhausts their connection limit, Tenant B is unaffected.

### 5. Verification Tests

The `make test` command includes specific negative tests to verify this isolation:

1.  **Database Isolation**: Attempts to connect to `tenant_b_db` using Tenant A's connection (Port 6432). This fails because Tenant A's PgBouncer does not know about Tenant B's database.
2.  **Authentication Isolation**: Attempts to authenticate as `user_a` on Tenant B's connection (Port 6433). This fails because `user_a` is not in Tenant B's `userlist.txt`.

Pass output looks like:
```
 [PASS] Tenant A blocked from Tenant B DB (Database not allowed)
 [PASS] Tenant A User blocked on Tenant B Port (Authentication failed)
```

## Configuration Details

**Tenant A (`pgbouncer_tenant_a.ini`)**:
```ini
[pgbouncer]
listen_port = 6432
auth_file = /etc/pgbouncer/userlist_tenant_a.txt
max_client_conn = 100
```

**Tenant B (`pgbouncer_tenant_b.ini`)**:
```ini
[pgbouncer]
listen_port = 6433
auth_file = /etc/pgbouncer/userlist_tenant_b.txt
max_client_conn = 50
```

**Systemd Template (`pgbouncer@.service`)**:
```ini
[Service]
ExecStart=/usr/sbin/pgbouncer /etc/pgbouncer/pgbouncer_%i.ini
```
Start instance with: `systemctl start pgbouncer@tenant_a`

## Benefits for `pg_hba.conf`

Instead of listing every single tenant user/IP rule in PostgreSQL's `pg_hba.conf`, you can simply trust the PgBouncer host/IP. Authentication is offloaded to the isolated PgBouncer instances.

```
# PostgreSQL pg_hba.conf
host    all             all             172.18.0.0/16           trust
```
*(In a real production setup, restrict this further to just the PgBouncer IP).*
