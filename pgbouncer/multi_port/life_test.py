import time
import threading
import psycopg2
import random
from rich.console import Console
from rich.table import Table
from rich.live import Live
from rich.layout import Layout
from rich.text import Text

# Configuration
PGBOUNCER_HOST = "localhost"
PORTS = [6432, 6433, 6434]
USER = "user1"
PASS = "user1"
DB = "testdb"

connection_stats = {port: {"active": 0, "total": 0} for port in PORTS}
active_connections = {port: [] for port in PORTS}
lock = threading.Lock()

def worker_thread(port):
    time.sleep(random.uniform(0, 2))
    conn_id = random.randint(1000, 9999)
    try:
        with lock:
            active_connections[port].append(conn_id)
            connection_stats[port]["active"] += 1
            connection_stats[port]["total"] += 1
            
        conn = psycopg2.connect(
            host=PGBOUNCER_HOST,
            port=port,
            user=USER,
            password=PASS,
            dbname=DB,
            connect_timeout=5
        )
        conn.autocommit = True
        
        # Keep alive for random duration
        duration = random.uniform(3, 8)
        start = time.time()
        while time.time() - start < duration:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
            time.sleep(1)
            
        conn.close()
        
    except Exception as e:
        pass
    finally:
        with lock:
            if conn_id in active_connections[port]:
                active_connections[port].remove(conn_id)
            connection_stats[port]["active"] = max(0, connection_stats[port]["active"] - 1)

def traffic_generator():
    while True:
        # Launch connections to random ports
        target_port = random.choice(PORTS)
        t = threading.Thread(target=worker_thread, args=(target_port,))
        t.daemon = True
        t.start()
        time.sleep(random.uniform(0.2, 0.8))

def generate_table():
    table = Table(title="Multi-Port Listening Test")
    table.add_column("Port", style="cyan", justify="center")
    table.add_column("Active Connections", style="green", justify="center")
    table.add_column("Total Processed", style="magenta", justify="center")
    table.add_column("Status", style="yellow", justify="center")
    
    with lock:
        for port in PORTS:
            active = connection_stats[port]["active"]
            total = connection_stats[port]["total"]
            
            # Simulate status bar
            bar_len = active
            bar = "█" * bar_len
            
            status = "LISTENING"
            style = "green"
            
            table.add_row(
                str(port), 
                str(active), 
                str(total),
                Text(bar, style="blue")
            )
            
    return table

def run_dashboard():
    console = Console()
    console.print("[bold green]Starting Multi-Port Traffic Generator...[/bold green]")
    
    # Start traffic generator
    t = threading.Thread(target=traffic_generator)
    t.daemon = True
    t.start()
    
    layout = Layout()
    
    try:
        with Live(generate_table(), refresh_per_second=4) as live:
            while True:
                live.update(generate_table())
                time.sleep(0.25)
    except KeyboardInterrupt:
        console.print("[bold red]Stopping test...[/bold red]")

if __name__ == "__main__":
    run_dashboard()
