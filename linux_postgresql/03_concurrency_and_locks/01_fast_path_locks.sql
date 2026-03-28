-- 01_fast_path_locks.sql
-- In PostgreSQL <= 17, local lock array holds 16 slots (FP_LOCK_SLOTS_PER_BACKEND).
-- We'll explicitly create and lock 20 tables to overflow into the central shared lock table.
-- Then we sleep, so you can inspect pg_stat_activity for LWLock contention.

DO $$ 
BEGIN
    -- Create dummy tables if they don't exist
    FOR i IN 1..20 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS public.dummy_table_%s (id serial primary key)', i);
    END LOOP;
END $$;

BEGIN;
-- This will consume more than 16 lock slots, spilling into shared memory locks
LOCK TABLE dummy_table_1 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_2 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_3 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_4 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_5 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_6 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_7 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_8 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_9 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_10 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_11 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_12 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_13 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_14 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_15 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_16 IN ACCESS SHARE MODE; -- Up to here fits in fast path
LOCK TABLE dummy_table_17 IN ACCESS SHARE MODE; -- Start spilling! Locks 17+ cause contention
LOCK TABLE dummy_table_18 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_19 IN ACCESS SHARE MODE;
LOCK TABLE dummy_table_20 IN ACCESS SHARE MODE;

-- Sleep for 60 seconds to lock the session.
-- Instruct users to open a new session during this time and run:
-- SELECT pid, wait_event_type, wait_event FROM pg_stat_activity WHERE wait_event_type = 'LWLock';
SELECT pg_sleep(60);

COMMIT;
