-- Create databases
CREATE DATABASE testdb1;
CREATE DATABASE testdb2;

-- Create users
CREATE USER admin WITH PASSWORD 'admin123' SUPERUSER;
CREATE USER monitor WITH PASSWORD 'monitor';
CREATE USER user1 WITH PASSWORD 'user1';
CREATE USER user2 WITH PASSWORD 'user2';

-- Setup testdb1 privileges
\c testdb1
REVOKE CONNECT ON DATABASE testdb1 FROM PUBLIC;
GRANT CONNECT ON DATABASE testdb1 TO user1;
-- Deny user2 on testdb1 implicitly (or explicitly if needed, but default is restrictive enough if we verify owner)
-- Create a table for verification
CREATE TABLE app_data (id SERIAL PRIMARY KEY, info TEXT);
INSERT INTO app_data (info) VALUES ('This is Database 1');
GRANT ALL ON TABLE app_data TO user1;

-- Setup testdb2 privileges
\c testdb2
REVOKE CONNECT ON DATABASE testdb2 FROM PUBLIC;
GRANT CONNECT ON DATABASE testdb2 TO user2;
CREATE TABLE app_data (id SERIAL PRIMARY KEY, info TEXT);
INSERT INTO app_data (info) VALUES ('This is Database 2');
GRANT ALL ON TABLE app_data TO user2;

-- Setup admin access
\c postgres
GRANT CONNECT ON DATABASE postgres TO admin, monitor;
