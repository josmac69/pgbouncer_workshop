-- 01_work_mem_scaling.sql
-- Demonstration of scaling work_mem over memory-intensive operations.

-- Turn OFF JIT for baseline
SET jit = off;

-- Example 1: 4MB work_mem - Simple Sort
SET work_mem = '4MB';
EXPLAIN ANALYZE
SELECT * FROM generate_series(1, 100000) AS t(val) ORDER BY val;
-- Notice how memory scales (approx 2x work_mem for this scale)

-- Example 2: Massive order with default 32MB work_mem
SET work_mem = '32MB';
EXPLAIN ANALYZE
SELECT * FROM generate_series(1, 100000000) AS t(val) ORDER BY val DESC;
-- Expected: ~ 1.6x work_mem

-- Example 3: Expanded 64MB work_mem
SET work_mem = '64MB';
EXPLAIN ANALYZE
SELECT * FROM generate_series(1, 100000000) AS t(val) ORDER BY val DESC;
-- Expected: ~ 1.4x work_mem

-- OBSERVE the 'Sort Method' in the output to see if it spills to disk (external merge)
