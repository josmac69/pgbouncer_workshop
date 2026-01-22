#!/bin/bash
# Comprehensive test demonstrating all connection limits

set -e

echo "=============================================="
echo "PgBouncer Connection Capping Demonstration"
echo "=============================================="
echo ""
echo "This script demonstrates three types of connection limits:"
echo "  1. max_user_connections = 3"
echo "  2. max_db_connections = 5"
echo ""

# PgBouncer connection details
PGBOUNCER_HOST="pgbouncer_cap"
PGBOUNCER_PORT="6432"

echo "=== Initial State ==="
echo ""
echo "Current PgBouncer pool status:"
docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;"

echo ""
echo "Current PgBouncer configuration:"
docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW CONFIG;" | grep -E "(max_db_connections|max_user_connections|max_client_conn)"

echo ""
echo "=== Test 1: User Connection Limit ==="
echo ""
echo "Opening 3 connections as user1 to testdb1..."

# Keep connections alive by running a long query
for i in 1 2 3; do
    PGPASSWORD=user1 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user1 -d testdb1 \
        -c "INSERT INTO test_table (username, data) VALUES ('user1', 'connection $i');" \
        -c "SELECT * FROM test_table WHERE username='user1';"
done

echo "✓ 3 connections succeeded"
echo ""
echo "Attempting 4th connection as user1..."
PGPASSWORD=user1 timeout 3 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user1 -d testdb2 \
    -c "SELECT 'Should not reach here';" 2>&1 || \
    echo "✗ 4th connection rejected/timed out (max_user_connections reached)"

echo ""
echo "=== Test 2: Database Connection Limit ==="
echo ""
echo "Testing max_db_connections by having multiple users connect to same database..."

# Connection attempts from different users to same database
echo "user1 connecting to testdb1..."
PGPASSWORD=user1 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user1 -d testdb1 \
    -c "SELECT 'user1' as username, count(*) as connections FROM test_table;" &

sleep 0.5

echo "user2 connecting to testdb1..."
PGPASSWORD=user2 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user2 -d testdb1 \
    -c "SELECT 'user2' as username;" &

sleep 0.5

echo "user3 connecting to testdb1..."
PGPASSWORD=user3 psql -h $PGBOUNCER_HOST -p $PGBOUNCER_PORT -U user3 -d testdb1 \
    -c "SELECT 'user3' as username;" &

wait

echo ""
echo "=== Current Pool Status ==="
docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;"

echo ""
echo "=== Statistics ==="
docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW STATS;"

echo ""
echo "=== Database Status ==="
docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW DATABASES;"

echo ""
echo "=============================================="
echo "Demonstration Complete!"
echo "=============================================="
echo ""
echo "Key Takeaways:"
echo "  • max_user_connections prevents a single user from exhausting connections"
echo "  • max_db_connections protects individual databases from overload"
echo "  • These limits work together to provide fair resource allocation"
echo "  • Connections exceeding limits are queued or rejected"
echo ""
