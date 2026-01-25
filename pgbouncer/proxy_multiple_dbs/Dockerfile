FROM debian:bookworm-slim

# Install PgBouncer and PostgreSQL client
RUN apt-get update && apt-get install -y \
    gnupg \
    wget \
    lsb-release \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y \
    pgbouncer \
    postgresql-client \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create postgres user if not exists (debian package usually creates it)
RUN id -u postgres &>/dev/null || useradd -r -U -d /var/lib/postgresql -s /bin/bash postgres

# Setup directories
RUN mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer /tmp && \
    chown -R postgres:postgres /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer

# Copy config files
COPY config/pgbouncer.ini /etc/pgbouncer/
COPY config/userlist.txt /etc/pgbouncer/

# Fix permissions
RUN chmod 644 /etc/pgbouncer/pgbouncer.ini && \
    chmod 600 /etc/pgbouncer/userlist.txt && \
    chown -R postgres:postgres /etc/pgbouncer

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

USER postgres

# Start PgBouncer
CMD ["/usr/sbin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
