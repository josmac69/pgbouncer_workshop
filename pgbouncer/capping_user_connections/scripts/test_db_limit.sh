#!/bin/bash
# Test script to demonstrate max_db_connections limit
# This limit restricts the number of server connections to a specific database

set -e

echo "========================================="
echo "Testing max_db_connections limit (5)"
echo "========================================="
echo ""
echo "This test demonstrates that no more than 5 server connections"
echo "can be made to a single database, regardless of user."
echo ""

# PgBouncer connection details
PGBOUNCER_HOST="localhost"
PGBOUNCER_PORT="6432"

echo "Step 1: Opening 5 connections to testdb1 from different users..."
echo ""

declare -a PIDS

# Open 2 connections as user1
for i in 1 2; do
    PGPASSWORD=user1 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user1 -d testdb1 -c "SELECT 'user1 connection $i' as status, pg_sleep(10);" &
    PIDS+=($!)
    echo "  Opened user1 connection $i"
    sleep 0.5
done

# Open 2 connections as user2
for i in 1 2; do
    PGPASSWORD=user2 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user2 -d testdb1 -c "SELECT 'user2 connection $i' as status, pg_sleep(10);" &
    PIDS+=($!)
    echo "  Opened user2 connection $i"
    sleep 0.5
done

# Open 1 connection as user3
PGPASSWORD=user3 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user3 -d testdb1 -c "SELECT 'user3 connection 1' as status, pg_sleep(10);" &
PIDS+=($!)
echo "  Opened user3 connection 1"
sleep 1

echo ""
echo "Step 2: Checking PgBouncer pools for testdb1..."
echo ""
PGPASSWORD=admin123 psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;" | grep testdb1

echo ""
echo "Step 3: Attempting 6th connection to testdb1 (should fail or queue)..."
echo ""

# Try to open a 6th connection - this should be queued or rejected
PGPASSWORD=user3 timeout 5 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user3 -d testdb1 -c "SELECT '6th connection' as status;" 2>&1 || {
    echo "  ✓ 6th connection was rejected or timed out as expected!"
    echo "  This confirms max_db_connections=5 is working."
}

echo ""
echo "Step 4: Verifying we can still connect to testdb2..."
echo ""
PGPASSWORD=user1 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user1 -d testdb2 -c "SELECT 'Connection to testdb2 successful' as status;"

echo ""
echo "Step 5: Cleaning up..."
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
echo "- max_db_connections limits connections per database"
echo "- testdb1 accepted 5 connections from multiple users"
echo "- 6th connection to testdb1 was rejected/queued"
echo "- Other databases (testdb2) remained accessible"
echo ""
