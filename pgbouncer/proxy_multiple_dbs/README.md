# PgBouncer Proxy Multiple Databases Example

This example demonstrates using PgBouncer as a proxy to route connections to different databases based on the database alias used by the client. This allows for a simplified client configuration where a single PgBouncer entry point serves multiple backend databases.

## Use Case

- **Single Entry Point**: Applications connect to one host/port.
- **Alias Routing**: Connection strings use aliases (`postgres1`, `postgres2`) which map to specific real databases (`testdb1`, `testdb2`).
- **User Isolation**: Ensures users only access their assigned databases.

## Configuration

pbbouncer.ini:
```ini
[databases]
postgres1 = host=postgres dbname=testdb1
postgres2 = host=postgres dbname=testdb2
```

## How to Run

1. **Start Services**:
   ```bash
   make build
   make up
   ```

2. **Run Verification**:
   ```bash
   make test
   ```
   This script verifies:
   - Connecting to `postgres1` routes to `testdb1`.
   - Connecting to `postgres2` routes to `testdb2`.
   - Cross-access is denied (e.g. `user1` cannot access `postgres2`).

3. **Check Status**:
   ```bash
   make status
   ```

4. **Clean Up**:
   ```bash
   make clean
   ```
