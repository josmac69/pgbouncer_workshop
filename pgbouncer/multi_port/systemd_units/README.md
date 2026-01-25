# Systemd Unit Examples

These files demonstrate how to configure multi-port listening on a standard Linux server (RedHat, Debian, Ubuntu) running systemd.

## Installation Instructions

1.  **Copy Unit Files**:
    Place the `.socket` and `.service` files in `/etc/systemd/system/`.

    ```bash
    sudo cp pgbouncer-multiport.socket /etc/systemd/system/
    sudo cp pgbouncer-multiport.service /etc/systemd/system/
    ```

2.  **Ensure Config Exists**:
    Ensure your config file exists at `/etc/pgbouncer/pgbouncer-multiport.ini` (or update the `.service` file to point to your actual config).
    *Note: Ensure `listen_port` is commented out or empty in the `.ini` file so PgBouncer uses the inherited sockets.*

3.  **Reload Systemd**:
    ```bash
    sudo systemctl daemon-reload
    ```

4.  **Start the Socket**:
    You only need to start and enable the **socket**, not the service directly. Systemd will start the service when the first connection arrives (or you can start both).

    ```bash
    sudo systemctl enable --now pgbouncer-multiport.socket
    ```

5.  **Verify**:
    Check that systemd is listening on the ports:
    ```bash
    ss -tlpn | grep 643
    # Should show systemd listening on 6432, 6433, 6434
    ```

    Connect to one of the ports:
    ```bash
    psql -p 6432 -h localhost -U admin testdb
    ```
    This triggers systemd to start `pgbouncer-multiport.service` immediately.
