#!/usr/bin/env python3
import threading
import time
import psycopg2
import sys

# Change parameters if your local test instance is different!
DB_PARAMS = {
    'dbname': 'postgres',
    'user': 'postgres',
    'host': '127.0.0.1',
    'port': '5432'
}

# High concurrency intended to trigger CPU context-switch bursts on the database accept() loop.
NUM_THREADS = 200

results = []

def worker(worker_id):
    start_time = time.time()
    try:
        # Rapid connection attempt
        conn = psycopg2.connect(**DB_PARAMS)
        conn.close()
        elapsed = time.time() - start_time
        results.append(elapsed)
    except psycopg2.OperationalError as e:
        print(f"Worker {worker_id} connection rejected: {e}")
    except Exception as e:
        print(f"Worker {worker_id} failed: {e}")

def main():
    print(f"Simulating thundering herd with {NUM_THREADS} concurrent database connection requests...")
    
    threads = []
    for i in range(NUM_THREADS):
        t = threading.Thread(target=worker, args=(i,))
        threads.append(t)
    
    start_all = time.time()
    for t in threads:
        t.start()
    
    for t in threads:
        t.join()
        
    if results:
        avg_latency = sum(results) / len(results)
        max_latency = max(results)
    else:
        avg_latency = max_latency = 0
        
    total_time = time.time() - start_all
    
    print(f"Total benchmark time: {total_time:.4f} seconds.")
    print(f"Average connection latency: {avg_latency:.4f} seconds.")
    print(f"Max connection latency: {max_latency:.4f} seconds.")
    print("\nTakeaway: As thread counts increase, `accept()` serialization creates large latency spikes.")
    print("This is exactly the type of workload Connection Poolers (like PgBouncer or Pgpool-II) are built to stabilize.")
    
if __name__ == "__main__":
    main()
