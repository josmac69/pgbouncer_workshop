-- 02_jit_memory_bloat.sql
-- Demonstrating JIT memory overhead using an aggregation query on 100M rows.

-- Set base configuration for consistency
-- Note: Requires running on a server capable of handling heavy CPU loads.
SET work_mem = '4MB';

-- Test 1: Baseline with JIT OFF
SET jit = off;
EXPLAIN ANALYZE
SELECT (i/100)::int AS grp, COUNT(*) 
FROM generate_series(1, 100000000) AS i 
GROUP BY grp;
-- Memory use should sit around 3.5x work_mem. Query execution might take a while.

-- Test 2: Enable JIT
SET jit = on;
EXPLAIN ANALYZE
SELECT (i/100)::int AS grp, COUNT(*) 
FROM generate_series(1, 100000000) AS i 
GROUP BY grp;
-- Expected output: Drastic memory inflation (e.g. up to 8.1x work_mem)

-- TIP: While these queries are running, use the Python scripts in `01_memory_basics` 
-- in a separate terminal to view the memory explosion.
