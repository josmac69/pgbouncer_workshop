# PgBouncer Workshop - Part 1 Visualizations

This directory contains standalone scripts created to visually demonstrate the core architectural concepts of PostgreSQL connection management highlighted in the presentation.

### Quick Start

We have provided a unified runner script to easily launch any of the required python or PSQL visualization tests interactively. 

```bash
./run_example.sh
```

### Prerequisites

To run the memory and connection simulators without the unified script, first install the Python package requirements:

```bash
pip install -r requirements.txt
```

*(Note: Running SQL files only requires `psql` access).*

### Directory Overview

#### `01_memory_basics`
* `01_idle_connection_memory.py`: Feed it a PostgreSQL backend `PID` to observe how standard process memory (USS, RSS, VMS, Shared, Data) reacts over the lifecycle of a connection using `psutil`.
* `02_smaps_parser.py`: Parse `/proc/<pid>/smaps` for a running backend. Proves how memory objects like `[heap]` and `[anonymous]` fluctuate during execution and visualizes Shared Buffers rendering as `/dev/zero (deleted)`.

#### `02_query_memory_impact`
* `01_work_mem_scaling.sql`: Shows exactly how PostgreSQL inflates query memory blocks (around 1.4x - 2.2x multipliers) to handle `ORDER BY` datasets varying with different `work_mem` sizes.
* `02_jit_memory_bloat.sql`: Recreates the shocking 8.1x `work_mem` multiplier seen on JIT-enabled queries contrasted with the baseline 3.5x multiplier.

#### `03_concurrency_and_locks`
* `01_fast_path_locks.sql`: An automated test deliberately exhausting the `16` array slots assigned to `FP_LOCK_SLOTS_PER_BACKEND` to force and demonstrate severe system lock contention.
* `02_thundering_herd_simulator.py`: Executes concurrent bursts of 200+ connection requests against the database bypassing any connection pooler. Showcases severe timing inflation as `accept()` begins queueing threads uncontrollably.
