#!/usr/bin/env python3
import sys

def parse_smaps(pid):
    filepath = f"/proc/{pid}/smaps"
    paths_data = {}

    try:
        with open(filepath, "r") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Process with PID {pid} not found or no access to /proc/{pid}/smaps")
        return

    current_path = None
    for line in lines:
        if "-" in line and " " in line:
            parts = line.split()
            if len(parts) >= 6:
                path = parts[-1] if len(parts) > 6 else "[anonymous]"
                current_path = path
                if current_path not in paths_data:
                    paths_data[current_path] = {"Size": 0, "Rss": 0, "Pss": 0, "Shr_Clean": 0, "Shr_Dirty": 0, "Prv_Clean": 0, "Prv_Dirty": 0}
        
        elif current_path and line.startswith("Size:"):
            paths_data[current_path]["Size"] += int(line.split()[1])
        elif current_path and line.startswith("Rss:"):
            paths_data[current_path]["Rss"] += int(line.split()[1])
        elif current_path and line.startswith("Pss:"):
            paths_data[current_path]["Pss"] += int(line.split()[1])
        elif current_path and line.startswith("Shared_Clean:"):
            paths_data[current_path]["Shr_Clean"] += int(line.split()[1])
        elif current_path and line.startswith("Shared_Dirty:"):
            paths_data[current_path]["Shr_Dirty"] += int(line.split()[1])
        elif current_path and line.startswith("Private_Clean:"):
            paths_data[current_path]["Prv_Clean"] += int(line.split()[1])
        elif current_path and line.startswith("Private_Dirty:"):
            paths_data[current_path]["Prv_Dirty"] += int(line.split()[1])

    print(f"{'Path':<30} {'Size':>10} {'Rss':>10} {'Pss':>10} {'Shr_Cln':>10} {'Shr_Drt':>10} {'Prv_Cln':>10} {'Prv_Drt':>10}")
    print("-" * 102)
    for path, data in sorted(paths_data.items(), key=lambda item: item[1]["Rss"], reverse=True)[:20]:
        # Truncate path if too long
        display_path = path if len(path) <= 28 else "..." + path[-25:]
        print(f"{display_path:<30} {data['Size']:>10} {data['Rss']:>10} {data['Pss']:>10} {data['Shr_Clean']:>10} {data['Shr_Dirty']:>10} {data['Prv_Clean']:>10} {data['Prv_Dirty']:>10}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./02_smaps_parser.py <PID>")
        sys.exit(1)
    parse_smaps(sys.argv[1])
