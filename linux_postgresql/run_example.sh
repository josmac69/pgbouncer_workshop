#!/bin/bash

# Main runner script for the PgBouncer Workshop - Part 1 Visualizations

WORK_DIR=$(dirname "$0")

# Change to WORK_DIR to ensure relative paths resolve correctly
cd "$WORK_DIR" || exit 1

check_and_install_dependencies() {
    echo ">>> Checking for psycopg2 system dependencies..."
    missing_deps=()
    for pkg in libpq-dev python3-dev gcc; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing_deps+=("$pkg")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo ">>> Missing system dependencies: ${missing_deps[*]}"
        echo ">>> Installing missing dependencies (requires sudo)..."
        sudo apt-get update
        sudo apt-get install -y "${missing_deps[@]}"
    else
        echo ">>> All system dependencies are present."
    fi
}

setup_virtualenv() {
    VENV_DIR=".venv"
    echo ">>> Checking Python virtual environment..."
    if [ ! -d "$VENV_DIR" ]; then
        echo ">>> Virtual environment not found. Creating one..."
        if ! dpkg -s python3-venv >/dev/null 2>&1; then
             echo ">>> python3-venv is not installed. Installing it (requires sudo)..."
             sudo apt-get update
             sudo apt-get install -y python3-venv
        fi
        python3 -m venv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        echo ">>> Updating pip and installing requirements..."
        pip install --upgrade pip
        pip install -r requirements.txt
    else
        echo ">>> Activating existing virtual environment..."
        source "$VENV_DIR/bin/activate"
    fi
}

check_and_install_dependencies
setup_virtualenv

while true; do
    echo ""
    echo "================================================="
    echo "  PgBouncer Workshop - Part 1 Visualizations"
    echo "================================================="
    echo "Please select an example to run:"
    echo ""
    echo "--- 01 Memory Basics ---"
    echo "1) Check Idle Connection Memory (psutil)"
    echo "2) Parse PostgreSQL smaps for Shared Buffers"
    echo ""
    echo "--- 02 Query Memory Impact ---"
    echo "3) work_mem Scaling Demonstration (SQL)"
    echo "4) JIT Memory Bloat Demonstration (SQL)"
    echo ""
    echo "--- 03 Concurrency and Locks ---"
    echo "5) Fast-path lock array overflow (SQL)"
    echo "6) Thundering Herd Simulator (Python)"
    echo ""
    echo "0) Exit"
    echo "================================================="
    echo ""
    
    read -p "Enter your choice [0-6]: " choice

    case $choice in
        1)
            read -p "Enter PostgreSQL backend PID to inspect: " pid
            if [ -n "$pid" ]; then
                python3 "$WORK_DIR/01_memory_basics/01_idle_connection_memory.py" "$pid"
            else
                echo "PID is required."
            fi
            ;;
        2)
            read -p "Enter PostgreSQL backend PID to parse smaps: " pid
            if [ -n "$pid" ]; then
                python3 "$WORK_DIR/01_memory_basics/02_smaps_parser.py" "$pid"
            else
                echo "PID is required."
            fi
            ;;
        3)
            echo "Running 01_work_mem_scaling.sql via psql (requires standard local config)..."
            psql -U postgres -d postgres -f "$WORK_DIR/02_query_memory_impact/01_work_mem_scaling.sql"
            ;;
        4)
            echo "Running 02_jit_memory_bloat.sql via psql (requires standard local config)..."
            psql -U postgres -d postgres -f "$WORK_DIR/02_query_memory_impact/02_jit_memory_bloat.sql"
            ;;
        5)
            echo "Running 01_fast_path_locks.sql via psql (requires standard local config)..."
            psql -U postgres -d postgres -f "$WORK_DIR/03_concurrency_and_locks/01_fast_path_locks.sql"
            ;;
        6)
            echo "Running 02_thundering_herd_simulator.py..."
            python3 "$WORK_DIR/03_concurrency_and_locks/02_thundering_herd_simulator.py"
            ;;
        0)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 0 and 6."
            ;;
    esac
    
    echo ""
    read -p "Press [Enter] to continue..."
done
