-- Initialize databases and users for PgBouncer connection capping example

-- Create test databases
CREATE DATABASE testdb1;
CREATE DATABASE testdb2;

-- Create test users with passwords
-- Password is same as username for simplicity (user1/user1, user2/user2, etc.)
CREATE USER user1 WITH PASSWORD 'user1';
CREATE USER user2 WITH PASSWORD 'user2';
CREATE USER user3 WITH PASSWORD 'user3';
CREATE USER admin WITH PASSWORD 'admin123' SUPERUSER;
CREATE USER monitor WITH PASSWORD 'monitor';

-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE testdb1 TO user1, user2, user3;
GRANT ALL PRIVILEGES ON DATABASE testdb2 TO user1, user2, user3;
GRANT CONNECT ON DATABASE postgres TO admin, monitor, user1, user2, user3;

-- Connect to testdb1 and create test tables
\c testdb1

-- Create a simple test table
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    connection_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data TEXT
);

-- Grant permissions on the table
GRANT ALL PRIVILEGES ON TABLE test_table TO user1, user2, user3;
GRANT ALL PRIVILEGES ON SEQUENCE test_table_id_seq TO user1, user2, user3;

-- Connect to testdb2 and create test tables
\c testdb2

CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    connection_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data TEXT
);

GRANT ALL PRIVILEGES ON TABLE test_table TO user1, user2, user3;
GRANT ALL PRIVILEGES ON SEQUENCE test_table_id_seq TO user1, user2, user3;

-- Return to postgres database
\c postgres

-- Create a helper view to see active connections
CREATE OR REPLACE VIEW connection_stats AS
SELECT 
    datname as database,
    usename as username,
    COUNT(*) as connection_count,
    array_agg(DISTINCT application_name) as applications,
    array_agg(DISTINCT state) as states
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY datname, usename
ORDER BY datname, usename;

GRANT SELECT ON connection_stats TO admin, monitor;

-- Display initial configuration
\echo '==================================='
\echo 'Database initialization complete!'
\echo '==================================='
\echo 'Created databases: testdb1, testdb2'
\echo 'Created users: user1, user2, user3, admin, monitor'
\echo 'Connection limits in pgbouncer.ini:'
\echo '  - max_db_connections: 5 per database'
\echo '  - max_user_connections: 3 per user'
\echo '==================================='
