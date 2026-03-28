#!/usr/bin/env python3
import sys
import psutil

def main():
    if len(sys.argv) != 2:
        print("Usage: ./01_idle_connection_memory.py <PID>")
        sys.exit(1)

    try:
        pid = int(sys.argv[1])
        process = psutil.Process(pid)
        print(f"PID: {pid}, Command: {' '.join(process.cmdline())}")
        
        mem_info = process.memory_full_info()
        print(f"rss:     {mem_info.rss / 1024 / 1024:>6.1f} MB")
        print(f"vms:     {mem_info.vms / 1024 / 1024:>6.1f} MB")
        print(f"shared:  {mem_info.shared / 1024 / 1024:>6.1f} MB")
        print(f"text:    {mem_info.text / 1024 / 1024:>6.1f} MB")
        print(f"lib:     {mem_info.lib / 1024 / 1024:>6.1f} MB")
        print(f"data:    {mem_info.data / 1024 / 1024:>6.1f} MB")
        print(f"dirty:   {mem_info.dirty / 1024 / 1024:>6.1f} MB")
        print(f"uss:     {mem_info.uss / 1024 / 1024:>6.1f} MB")
        print(f"pss:     {mem_info.pss / 1024 / 1024:>6.1f} MB")
        print(f"swap:    {mem_info.swap / 1024 / 1024:>6.1f} MB")
    except psutil.NoSuchProcess:
        print(f"Process with PID {pid} not found.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
