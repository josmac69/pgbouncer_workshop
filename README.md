# PgBouncer Workshop

This directory contains all materials for the workshop **"PgBouncer - Everything, Everywhere, All At Once About This Tool"** presented at Prague PostgreSQL Developer Day 2026.

## Abstract
PgBouncer is widely used in PostgreSQL environments. Like any connection pooler, it has clear strengths and limits, and it has been applied across a range of production patterns. Recent releases added support for protocol‑level prepared statements in transaction and statement pooling; in 2025 the project also made progress toward a multithreaded design.

In this half‑day workshop we examine how PgBouncer’s current single‑threaded event loop works and outline the proposed multithreaded approach. We’ll cover practical and experimental use cases and the configuration edges that matter in production—like scaling across cores with multiple processes on the same port via so_reuseport and peering and other interesting solutions. Attendees receive runnable examples for the key use cases as well as commented list of online resources.

## Key takeaways

* Know the trade‑offs of this connection pooler
* Prepared statements can work in transaction/statement pooling
* PgBouncer is single‑threaded today; scale across cores with multiple processes
* PgBouncer can help with HA/failover — but not alone
* A multithreaded architecture is on the horizon

## Examples

The `pgbouncer/` directory contains several self-contained examples demonstrating specific use cases. Each example includes a `README.md` with detailed instructions.

*   **[Connection Capping](pgbouncer/capping_user_connections/README.md)**
    Demonstrates how to `max_user_connections` and `max_db_connections` to prevent resource exhaustion. Includes a life test visualizing connection queueing when limits are reached.

*   **[Multiple Instances (Multi-Core Scaling)](pgbouncer/multiple_instances_example/README.md)**
    A robust setup using `systemd` and `SO_REUSEPORT` to run multiple PgBouncer processes on the same port, allowing the single-threaded pooler to scale across multiple CPU cores.

*   **[Multi-Port Listening](pgbouncer/multi_port/README.md)**
    Shows how a *single* PgBouncer instance can serve connections on multiple ports (e.g., 6432, 6433, 6434) using systemd socket activation—useful for consolidating legacy endpoints.

*   **[Database Proxying](pgbouncer/proxy_multiple_dbs/README.md)**
    Uses PgBouncer as a routing layer, mapping connection aliases (e.g., `db_alias_1`) to specific backend databases, simplifying client configuration and enforcing access boundaries.
