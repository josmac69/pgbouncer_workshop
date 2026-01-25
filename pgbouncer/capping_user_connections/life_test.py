import time
import threading
import psycopg2
import random
from rich.console import Console
from rich.table import Table
from rich.live import Live
from rich.layout import Layout
from rich.panel import Panel
from rich.text import Text

# Configuration
PGBOUNCER_HOST = "localhost"
PGBOUNCER_PORT = 6432
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"
DB_NAME = "pgbouncer"

# Test scenarios
TEST_USERS = [
    {"user": "user1", "pass": "user1", "db": "testdb1", "limit": 3, "count": 15},  # User cap test
    {"user": "user2", "pass": "user2", "db": "testdb1", "limit": 0, "count": 15},  # DB cap test contribution
]

console = Console()
connections = []
connection_statuses = {}

def get_admin_connection():
    try:
        conn = psycopg2.connect(
            host=PGBOUNCER_HOST,
            port=PGBOUNCER_PORT,
            user=ADMIN_USER,
            password=ADMIN_PASS,
            dbname=DB_NAME
        )
        conn.autocommit = True
        return conn
    except Exception as e:
        return None

def worker_thread(user_idx, user_config, conn_idx):
    user = user_config["user"]
    password = user_config["pass"]
    dbname = user_config["db"]
    key = f"{user}_{dbname}_{conn_idx}"
    
    connection_statuses[key] = "CONNECTING"
    
    try:
        conn = psycopg2.connect(
            host=PGBOUNCER_HOST,
            port=PGBOUNCER_PORT,
            user=user,
            password=password,
            dbname=dbname,
            connect_timeout=5
        )
        conn.autocommit = True
        
        # Connection established but might be queued by PgBouncer
        connection_statuses[key] = "QUEUED"
        
        # Try to run a query to confirm we are truly active
        try:
            with conn.cursor() as cur:
                # Set a query timeout to detect if we are strictly queued for too long?
                # Actually, blocking here IS the queued state.
                cur.execute("SELECT 1")
                connection_statuses[key] = "ACTIVE"
                
                # Keep connection open and active
                while True:
                    cur.execute("SELECT 1")
                    time.sleep(random.uniform(0.5, 2.0))
        except Exception as e:
            connection_statuses[key] = "ERROR"
            conn.close()
            
    except Exception as e:
        connection_statuses[key] = "REJECTED"

def start_load():
    for u_idx, u_conf in enumerate(TEST_USERS):
        for i in range(u_conf["count"]):
            t = threading.Thread(target=worker_thread, args=(u_idx, u_conf, i))
            t.daemon = True
            t.start()
            time.sleep(0.2) 

def generate_table():
    table = Table(title="Connection Capping Live Test")
    table.add_column("User", style="cyan")
    table.add_column("Database", style="magenta")
    table.add_column("Conn #", style="green")
    table.add_column("Status", style="yellow")
    
    # Sort keys for stable display
    for key in sorted(connection_statuses.keys()):
        parts = key.split("_")
        user = parts[0]
        db = parts[1]
        idx = parts[2]
        status = connection_statuses[key]
        
        style = "green" if status == "ACTIVE" else "red"
        if status == "CONNECTING":
            style = "yellow"
            
        table.add_row(user, db, idx, Text(status, style=style))
        
    return table

def generate_limits_info():
    table = Table(title="Configured Limits")
    table.add_column("Limit Type", style="bold")
    table.add_column("Value", style="cyan")
    
    table.add_row("max_user_connections", "3")
    table.add_row("max_db_connections", "5")
    
    return table

def run_dashboard():
    layout = Layout()
    layout.split_row(
        Layout(name="main"),
        Layout(name="sidebar", ratio=2)
    )
    
    try:
        with Live(layout, refresh_per_second=4) as live:
            while True:
                layout["main"].update(generate_limits_info())
                layout["sidebar"].update(generate_table())
                time.sleep(0.25)
    except KeyboardInterrupt:
        console.print("[bold red]Stopping test...[/bold red]")

if __name__ == "__main__":
    console.print("[bold green]Starting Capping Life Test...[/bold green]")
    start_load()
    run_dashboard()
