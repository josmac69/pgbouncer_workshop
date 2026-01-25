#!/bin/bash
set -e

echo "========================================="
echo "Testing PgBouncer Database Proxy"
echo "========================================="
echo ""
echo "Goal: Verify that 'postgres1' routes to 'testdb1' and 'postgres2' routes to 'testdb2'."
echo ""

# Configuration - Using localhost since script runs inside container
HOST="localhost"
PORT="6432"

echo "Step 1: Test connection alias 'postgres1' (as user1)..."
# Should connect to testdb1 and see "This is Database 1"
RESULT=$(PGPASSWORD=user1 psql -h $HOST -p $PORT -U user1 -d postgres1 -t -c "SELECT info FROM app_data;" 2>/dev/null || echo "FAIL")
if [[ $RESULT == *"This is Database 1"* ]]; then
    echo "  ✓ Success! Connected to postgres1 and retrieved data from testdb1."
else
    echo "  ✗ Failed! Expected data 'This is Database 1', got: $RESULT"
    exit 1
fi

echo ""
echo "Step 2: Test connection alias 'postgres2' (as user2)..."
# Should connect to testdb2 and see "This is Database 2"
RESULT=$(PGPASSWORD=user2 psql -h $HOST -p $PORT -U user2 -d postgres2 -t -c "SELECT info FROM app_data;" 2>/dev/null || echo "FAIL")
if [[ $RESULT == *"This is Database 2"* ]]; then
    echo "  ✓ Success! Connected to postgres2 and retrieved data from testdb2."
else
    echo "  ✗ Failed! Expected data 'This is Database 2', got: $RESULT"
    exit 1
fi

echo ""
echo "Step 3: Verify User Isolation (Negative Test)..."
echo "3a. user1 trying to access postgres2 (mapped to testdb2)..."
# user1 does not exist/have permissions on testdb2 (or at least mapped that way implicitly via connect string)
# Actually, pgbouncer connects to testdb2 using user1. init-db.sql did NOT grant connect on testdb2 to user1.
if PGPASSWORD=user1 psql -h $HOST -p $PORT -U user1 -d postgres2 -c "\q" 2>/dev/null; then
    echo "  ✗ Unexpected success! user1 should not access postgres2."
    exit 1
else
    echo "  ✓ Rejected as expected (user1 cannot access testdb2)."
fi

echo "3b. user2 trying to access postgres1 (mapped to testdb1)..."
if PGPASSWORD=user2 psql -h $HOST -p $PORT -U user2 -d postgres1 -c "\q" 2>/dev/null; then
    echo "  ✗ Unexpected success! user2 should not access postgres1."
    exit 1
else
    echo "  ✓ Rejected as expected (user2 cannot access testdb1)."
fi

echo ""
echo "========================================="
echo "Proxy Verification Complete!"
echo "========================================="
