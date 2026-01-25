CREATE DATABASE tenant_a_db;
CREATE USER user_a WITH PASSWORD 'password_a';
GRANT ALL ON DATABASE tenant_a_db TO user_a;
-- Grant schema usage usually needed too, but for example plain db grant is fine or owner.
ALTER DATABASE tenant_a_db OWNER TO user_a;

CREATE DATABASE tenant_b_db;
CREATE USER user_b WITH PASSWORD 'password_b';
GRANT ALL ON DATABASE tenant_b_db TO user_b;
ALTER DATABASE tenant_b_db OWNER TO user_b;
