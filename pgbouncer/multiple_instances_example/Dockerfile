FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd, pgbouncer, postgresql-client, and utilities
RUN apt-get update && apt-get install -y \
	systemd \
	systemd-sysv \
	pgbouncer \
	postgresql-client \
	procps \
	net-tools \
	curl \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Remove unnecessary systemd services
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
	ls | grep -v systemd-tmpfiles-setup | xargs rm -f && \
	rm -f /lib/systemd/system/multi-user.target.wants/* \
	/etc/systemd/system/*.wants/* \
	/lib/systemd/system/local-fs.target.wants/* \
	/lib/systemd/system/sockets.target.wants/*udev* \
	/lib/systemd/system/sockets.target.wants/*initctl* \
	/lib/systemd/system/basic.target.wants/* \
	/lib/systemd/system/anaconda.target.wants/* \
	/lib/systemd/system/plymouth* \
	/lib/systemd/system/systemd-update-utmp*

# Create postgres user if it doesn't exist
RUN id -u postgres &>/dev/null || useradd -r -U -d /var/lib/postgresql -s /bin/bash postgres

# Create necessary directories
RUN mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer /tmp && \
	chown -R postgres:postgres /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer

# Copy systemd unit files to the container
COPY config/pgbouncer@.socket /etc/systemd/system/
COPY config/pgbouncer@.service /etc/systemd/system/

# Copy PgBouncer configuration files
COPY config/pgbouncer.ini /etc/pgbouncer/
COPY config/userlist.txt /etc/pgbouncer/

# Set permissions
RUN chmod 644 /etc/pgbouncer/pgbouncer.ini && \
	chmod 600 /etc/pgbouncer/userlist.txt && \
	chown -R postgres:postgres /etc/pgbouncer

# Enable systemd sockets for multiple instances
RUN systemctl enable pgbouncer@50001.socket && \
	systemctl enable pgbouncer@50002.socket && \
	systemctl enable pgbouncer@50003.socket && \
	systemctl enable pgbouncer@50004.socket

# Expose ports
# 6432 - Main PgBouncer port (shared by all instances via SO_REUSEPORT)
# 50001-50004 - Admin ports for each instance
EXPOSE 6432 50001 50002 50003 50004

# Use systemd as init system
CMD ["/lib/systemd/systemd"]
