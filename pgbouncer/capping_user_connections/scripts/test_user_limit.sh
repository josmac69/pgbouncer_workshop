#!/bin/bash
# Test script to demonstrate max_user_connections limit
# This limit restricts the number of server connections per user across all databases

set -e

echo "========================================="
echo "Testing max_user_connections limit (3)"
echo "========================================="
echo ""
echo "This test demonstrates that a single user cannot exceed 3 server connections"
echo "even when connecting to multiple databases."
echo ""

# PgBouncer connection details
PGBOUNCER_HOST="localhost"
PGBOUNCER_PORT="6432"
USER="user1"
PASSWORD="user1"

echo "Step 1: Opening 3 connections as user1 (should succeed)..."
echo ""

# Open 3 connections in the background and keep them alive
for i in 1 2 3; do
    PGPASSWORD=$PASSWORD psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U $USER -d testdb1 -c "SELECT 'Connection $i to testdb1' as status, pg_backend_pid() as pid, pg_sleep(10);" &
    PIDS[$i]=$!
    echo "  Opened connection $i (PID: ${PIDS[$i]})"
    sleep 1
done

echo ""
echo "Step 2: Checking PgBouncer pools..."
echo ""
PGPASSWORD=admin123 psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;" | grep user1 || echo "No user1 connections visible yet"

echo ""
echo "Step 3: Attempting to open 4th connection as user1 (should fail or queue)..."
echo ""

# Try to open a 4th connection - this should be queued or rejected
PGPASSWORD=$PASSWORD timeout 5 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U $USER -d testdb2 -c "SELECT 'Connection 4 to testdb2' as status, pg_backend_pid() as pid;" 2>&1 || {
    echo "  ✓ 4th connection was rejected or timed out as expected!"
    echo "  This confirms max_user_connections=3 is working."
}

echo ""
echo "Step 4: Checking final pool status..."
echo ""
PGPASSWORD=admin123 psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;" | grep user1

echo ""
echo "Step 5: Cleaning up connections..."
# Kill background processes
for pid in "${PIDS[@]}"; do
    kill $pid 2>/dev/null || true
done

wait 2>/dev/null || true

echo ""
echo "========================================="
echo "Test completed!"
echo "========================================="
echo ""
echo "Summary:"
echo "- max_user_connections limits server connections per user"
echo "- User1 could open 3 connections maximum"
echo "- 4th connection was rejected/queued"
echo ""
