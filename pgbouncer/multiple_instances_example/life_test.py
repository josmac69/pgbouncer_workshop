import time
import threading
import random
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from rich.console import Console
from rich.live import Live
from rich.table import Table
from rich.layout import Layout
from rich.panel import Panel
from datetime import datetime
import atexit
import sys

# Configuration
DB_HOST = "localhost"
DB_PORT = 6432  # Main PgBouncer port
ADMIN_PORTS = [50001, 50002, 50003, 50004]
DB_USER = "pgbouncer"  # Using pgbouncer user which is admin and has access
DB_PASS = "pgbouncer"
TARGET_DB = "testdb"

# Global state for monitoring
client_stats = {}
running = True
console = Console()

def get_connection(port=DB_PORT, dbname=TARGET_DB, user=DB_USER, password=DB_PASS):
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=port,
            dbname=dbname,
            user=user,
            password=password
        )
        # conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        return conn
    except Exception as e:
        # console.print(f"[red]Connection failed to port {port}: {e}[/red]")
        return None

def setup_database():
    """Create table and initial data if not exists."""
    console.print("[yellow]Initializing database...[/yellow]")
    # Connect directly to Postgres to setup schema if needed, but here we go through pgbouncer
    # Assuming the database 'testdb' exists (created by docker-compose)
    conn = get_connection(port=DB_PORT, dbname=TARGET_DB)
    if not conn:
        console.print("[red]Could not connect to database for setup. Ensure 'make up' is running.[/red]")
        sys.exit(1)
    
    try:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS usage_logs (
                id SERIAL PRIMARY KEY,
                client_id INT,
                action VARCHAR(20),
                data TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        console.print("[green]Database initialized.[/green]")
    except Exception as e:
        console.print(f"[red]Setup failed: {e}[/red]")
    finally:
        conn.close()

def client_worker(client_id):
    """Simulates a client performing operations."""
    connection_log = []
    
    while running:
        try:
            conn = get_connection()
            if not conn:
                time.sleep(1)
                continue
                
            cur = conn.cursor()
            
            # Simulate session duration
            session_duration = random.randint(3, 10)
            start_time = time.time()
            
            while time.time() - start_time < session_duration:
                op = random.choice(['INSERT', 'SELECT', 'UPDATE'])
                
                try:
                    if op == 'INSERT':
                        data = f"Data-{random.randint(1, 1000)}"
                        cur.execute("INSERT INTO usage_logs (client_id, action, data) VALUES (%s, %s, %s)", (client_id, op, data))
                    elif op == 'SELECT':
                        cur.execute("SELECT count(*) FROM usage_logs")
                        cur.fetchone()
                    elif op == 'UPDATE':
                        cur.execute("UPDATE usage_logs SET created_at = NOW() WHERE client_id = %s", (client_id,))
                    
                    conn.commit()
                except Exception as e:
                    conn.rollback()
                    # print(f"Client {client_id} error: {e}")
                
                time.sleep(random.uniform(0.1, 0.5))
                
            conn.close()
            # Random wait before reconnecting
            time.sleep(random.uniform(0.5, 2.0))
            
        except Exception as e:
            time.sleep(1)

def monitor_instances():
    """Polls admin consoles of each instance to see connected clients."""
    global client_stats
    
    while running:
        snapshot = {}
        for port in ADMIN_PORTS:
            # Connect to admin console 'pgbouncer' db
            try:
                # userlist.txt for admin is usually same, pass pgbouncer/pgbouncer
                conn = get_connection(port=port, dbname="pgbouncer", user="pgbouncer", password="pgbouncer")
                if conn:
                    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
                    cur = conn.cursor()
                    # SHOW CLIENTS returns data about connected clients
                    cur.execute("SHOW CLIENTS;")
                    rows = cur.fetchall()
                    # Count clients connected to 'testdb' (excluding admin console itself)
                    count = sum(1 for r in rows if r[1] == 'pgbouncer' and r[0] == 'testdb') # r[0]=database, r[1]=user
                    # Actually, we are using user 'pgbouncer' for clients too in this simplified setup
                    # Let's count all non-admin connections. SHOW CLIENTS columns: type, user, database, state, addr, port, local_addr, local_port...
                    # Column indices can vary by version, but usually:
                    # 0: type, 1: user, 2: database
                    
                    # Let's try to get column names
                    col_names = [desc[0] for desc in cur.description]
                    
                    # Fallback or map based on names
                    # We just want total count of client connections
                    snapshot[port] = len(rows)
                    conn.close()
                else:
                    snapshot[port] = -1 # Error
            except Exception:
                 snapshot[port] = -1

        client_stats = snapshot
        time.sleep(0.5)

def generate_layout():
    layout = Layout()
    layout.split(
        Layout(name="header", size=3),
        Layout(name="main", ratio=1)
    )
    return layout

def generate_table():
    table = Table(title="PgBouncer Instance Load Balancing Real-Time")
    table.add_column("Instance Port", justify="center", style="cyan", no_wrap=True)
    table.add_column("Status", justify="center")
    table.add_column("Active Clients", justify="right", style="green")
    
    total_conns = 0
    
    sorted_ports = sorted(ADMIN_PORTS)
    
    for port in sorted_ports:
        count = client_stats.get(port, 0)
        
        status = "[bold green]ONLINE[/bold green]"
        count_display = str(count)
        
        if count == -1:
            status = "[bold red]OFFLINE[/bold red]"
            count_display = "-"
        else:
            total_conns += count
            
        table.add_row(
            str(port),
            status,
            count_display
        )
        
    table.add_section()
    table.add_row("TOTAL", "", str(total_conns), style="bold white")
    
    return Panel(table)

def main():
    setup_database()
    
    # Start monitor thread
    mon_thread = threading.Thread(target=monitor_instances, daemon=True)
    mon_thread.start()
    
    # Start client threads
    num_clients = 20
    console.print(f"[yellow]Starting {num_clients} client threads...[/yellow]")
    threads = []
    for i in range(num_clients):
        t = threading.Thread(target=client_worker, args=(i,), daemon=True)
        t.start()
        threads.append(t)
        
    console.print("[green]System running. Press Ctrl+C to stop.[/green]")
    
    layout = generate_layout()
    layout["header"].update(Panel("PgBouncer Multiple Instances Life Test", style="bold white on blue"))
    
    with Live(generate_table(), refresh_per_second=4) as live:
        try:
            while True:
                live.update(generate_table())
                time.sleep(0.25)
        except KeyboardInterrupt:
            global running
            running = False
            console.print("\n[yellow]Stopping...[/yellow]")

if __name__ == "__main__":
    main()
