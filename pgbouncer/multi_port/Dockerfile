FROM debian:bookworm-slim

# Install PgBouncer, Systemd (for socket activate), and generic tools
RUN apt-get update && apt-get install -y \
    gnupg \
    wget \
    lsb-release \
    systemd \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y \
    pgbouncer \
    postgresql-client \
    procps \
    python3 \
    python3-venv \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create postgres user
RUN id -u postgres &>/dev/null || useradd -r -U -d /var/lib/postgresql -s /bin/bash postgres

# Config directories
RUN mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer /tmp && \
    chown -R postgres:postgres /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer

# Copy config
COPY config/pgbouncer.ini /etc/pgbouncer/
COPY config/userlist.txt /etc/pgbouncer/

# Fix permissions
RUN chmod 644 /etc/pgbouncer/pgbouncer.ini && \
    chmod 600 /etc/pgbouncer/userlist.txt && \
    chown -R postgres:postgres /etc/pgbouncer

COPY life_test.py /life_test.py

USER postgres

# Use systemd-socket-activate to bind ports and pass FD to pgbouncer
# We listen on 6432, 6433, 6434
CMD ["/usr/bin/systemd-socket-activate", "-l", "6432", "-l", "6433", "-l", "6434", "/usr/sbin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
